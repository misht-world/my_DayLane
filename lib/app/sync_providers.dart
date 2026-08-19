import 'dart:async';

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
    this.message,
    this.lastSyncAt,
    this.loaded = false,
  });

  final SyncConfig config;
  final SyncPhase phase;
  final String? message;
  final DateTime? lastSyncAt;
  final bool loaded;

  SyncUiState copyWith({
    SyncConfig? config,
    SyncPhase? phase,
    Object? message = _keep,
    DateTime? lastSyncAt,
    bool? loaded,
  }) =>
      SyncUiState(
        config: config ?? this.config,
        phase: phase ?? this.phase,
        message: message == _keep ? this.message : message as String?,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        loaded: loaded ?? this.loaded,
      );

  static const _keep = Object();
}

/// Состояние и управление синхронизацией: загрузка настроек, ручной запуск,
/// периодический авто-синк, сохранение/сброс настроек.
class SyncController extends Notifier<SyncUiState> {
  Timer? _timer;
  bool _busy = false;

  @override
  SyncUiState build() {
    ref.onDispose(() => _timer?.cancel());
    _load();
    return const SyncUiState();
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

  /// Один проход синхронизации. Не запускается повторно, если уже идёт.
  Future<void> syncNow() async {
    if (_busy) return;
    final store = state.config.store();
    if (store == null) {
      state = state.copyWith(
          phase: SyncPhase.error, message: 'Заполните репозиторий и токен');
      return;
    }
    _busy = true;
    state = state.copyWith(phase: SyncPhase.syncing, message: null);
    try {
      final res = await ref.read(syncServiceProvider).syncOnce(store);
      state = state.copyWith(
        phase: SyncPhase.ok,
        lastSyncAt: DateTime.now(),
        message: _summary(res),
      );
    } on SyncException catch (e) {
      state = state.copyWith(phase: SyncPhase.error, message: e.message);
    } catch (e) {
      state = state.copyWith(phase: SyncPhase.error, message: '$e');
    } finally {
      _busy = false;
    }
  }

  String _summary(SyncResult r) {
    if (!r.changedLocally && !r.pushedRemote) return 'Уже синхронизировано';
    final parts = <String>[
      if (r.applied > 0) '↓ ${r.applied}',
      if (r.deleted > 0) '− ${r.deleted}',
      if (r.pushed > 0) '↑ ${r.pushed}',
    ];
    return parts.isEmpty ? 'Готово' : parts.join('  ');
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);
