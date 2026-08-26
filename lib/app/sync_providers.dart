import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../services/sync_config.dart';
import '../services/sync_service.dart';
import '../services/sync_transport.dart';
import 'providers.dart';

/// Сервис синхронизации поверх общей БД.
final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(databaseProvider)),
);

/// Как часто автоматически синхронизировать, пока приложение открыто.
const Duration _kAutoSyncEvery = Duration(minutes: 2);

enum SyncPhase { idle, syncing, ok, error }

class SyncUiState {
  const SyncUiState({
    this.config = const SyncConfig(),
    this.phase = SyncPhase.idle,
    this.result,
    this.errorKind,
    this.lastSyncAt,
    this.loaded = false,
  });

  final SyncConfig config;
  final SyncPhase phase;

  /// Итог последнего успешного синка (счётчики нейтральны к языку).
  final SyncResult? result;

  /// Тип последней ошибки — текст локализуется в UI по нему.
  final SyncErrorKind? errorKind;
  final DateTime? lastSyncAt;
  final bool loaded;

  SyncUiState copyWith({
    SyncConfig? config,
    SyncPhase? phase,
    Object? result = _keep,
    Object? errorKind = _keep,
    DateTime? lastSyncAt,
    bool? loaded,
  }) =>
      SyncUiState(
        config: config ?? this.config,
        phase: phase ?? this.phase,
        result: result == _keep ? this.result : result as SyncResult?,
        errorKind:
            errorKind == _keep ? this.errorKind : errorKind as SyncErrorKind?,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        loaded: loaded ?? this.loaded,
      );

  static const _keep = Object();
}

/// Состояние и управление синхронизацией: загрузка настроек, ручной запуск,
/// периодический авто-синк, сохранение/сброс настроек.
class SyncController extends Notifier<SyncUiState>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _nudgeTimer;
  bool _busy = false;

  @override
  SyncUiState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
      _nudgeTimer?.cancel();
    });
    // Локальное изменение любого дела (правка/галочка/добавление/удаление —
    // всё бампит строку в tasks) → выгрузить вскоре, пока приложение открыто.
    // На закрытие Android не оставляет времени доделать сетевой запрос, поэтому
    // надёжнее синкать сразу после самой правки, а не «при выходе».
    ref.listen(tasksProvider, (_, _) => _nudge());
    _load();
    return const SyncUiState();
  }

  /// Отложенный синк после локальной правки (дебаунс, чтобы серия изменений
  /// свелась к одной выгрузке). Применение удалённых изменений тоже дёрнет этот
  /// сигнал, но тогда план окажется пустым — лишний проход безвреден и затухает.
  void _nudge() {
    if (!kConnected || !state.config.isComplete) return;
    _nudgeTimer?.cancel();
    _nudgeTimer = Timer(const Duration(seconds: 3), () => syncNow());
  }

  /// Синк по жизненному циклу приложения: при возврате — подтянуть свежее,
  /// при сворачивании/закрытии — выгрузить свои изменения (best-effort:
  /// система даёт короткое окно, но быстрый PUT обычно успевает).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kConnected || !this.state.config.isComplete) return;
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(syncNow());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _load() async {
    final cfg = await const SyncConfigStore().load();
    state = state.copyWith(config: cfg, loaded: true);
    _reschedule();
    // Синк при старте, если всё настроено.
    if (kConnected && cfg.isComplete) unawaited(syncNow());
  }

  void _reschedule() {
    _timer?.cancel();
    if (kConnected && state.config.isComplete) {
      _timer = Timer.periodic(_kAutoSyncEvery, (_) => syncNow());
    }
  }

  Future<void> saveConfig(SyncConfig cfg) async {
    await const SyncConfigStore().save(cfg);
    state = state.copyWith(config: cfg);
    _reschedule();
  }

  Future<void> disconnect() async {
    _timer?.cancel();
    await const SyncConfigStore().clear();
    state = const SyncUiState(loaded: true);
  }

  /// Публикует настройку Телеграм-дайджеста в sync-репозиторий (`digest.json`),
  /// откуда её читает скрипт на сервере. Возвращает признак «не настроено» и/или
  /// тип ошибки — текст локализуется в UI.
  Future<({bool needsConfig, SyncErrorKind? error})> publishDigest(
      bool enabled, int timeMinutes) async {
    final c = state.config;
    if (!c.isComplete) return (needsConfig: true, error: null);
    final store = GitHubStore(
        owner: c.owner,
        repo: c.repo,
        token: c.token,
        branch: c.branch,
        path: 'digest.json');
    String two(int v) => v.toString().padLeft(2, '0');
    final payload = {
      'enabled': enabled,
      'time': '${two(timeMinutes ~/ 60)}:${two(timeMinutes % 60)}',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      // до 3 попыток при гонке sha
      for (var i = 0;; i++) {
        final rf = await store.pull();
        try {
          await store.push(payload, rf.sha);
          return (needsConfig: false, error: null);
        } on SyncConflictException {
          if (i >= 3) rethrow;
        }
      }
    } on SyncException catch (e) {
      return (needsConfig: false, error: e.kind);
    }
  }

  /// Один проход синхронизации. Не запускается повторно, если уже идёт.
  Future<void> syncNow() async {
    if (_busy) return;
    final store = state.config.store();
    if (store == null) {
      // Нет репозитория/токена — errorKind null; UI покажет «заполните…».
      state = state.copyWith(
          phase: SyncPhase.error, errorKind: null, result: null);
      return;
    }
    _busy = true;
    state = state.copyWith(phase: SyncPhase.syncing, errorKind: null);
    try {
      final res = await ref.read(syncServiceProvider).syncOnce(store);
      state = state.copyWith(
        phase: SyncPhase.ok,
        lastSyncAt: DateTime.now(),
        result: res,
        errorKind: null,
      );
    } on SyncException catch (e) {
      state = state.copyWith(phase: SyncPhase.error, errorKind: e.kind);
    } catch (_) {
      state = state.copyWith(
          phase: SyncPhase.error, errorKind: SyncErrorKind.other);
    } finally {
      _busy = false;
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);
