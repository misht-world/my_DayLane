import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/sync_providers.dart';
import '../../core/theme.dart';
import '../../data/db.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sync_transport.dart';

/// Настройка утреннего Телеграм-дайджеста (только connected). Хранится локально
/// и публикуется в sync-репозиторий (`digest.json`), откуда её читает скрипт на
/// сервере. Требует настроенной синхронизации (репозиторий + токен).
class DigestSettingsSection extends ConsumerWidget {
  const DigestSettingsSection({super.key});

  String _fmt(int minutes) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
    required int minutes,
  }) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(databaseProvider).updateSettings(AppSettingsCompanion(
          digestEnabled: Value(enabled),
          digestTimeMinutes: Value(minutes),
        ));
    final res = await ref
        .read(syncControllerProvider.notifier)
        .publishDigest(enabled, minutes);
    final String text;
    if (res.needsConfig) {
      text = l.digestConfigureSyncFirst;
    } else if (res.error != null) {
      text = switch (res.error!) {
        SyncErrorKind.network => l.syncErrNetwork,
        SyncErrorKind.auth => l.syncErrAuth,
        _ => l.syncErrOther,
      };
    } else {
      text = l.digestSaved;
    }
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider).value;
    final configured = ref.watch(syncControllerProvider).config.isComplete;
    if (s == null) return const SizedBox.shrink();
    final enabled = s.digestEnabled;
    final minutes = s.digestTimeMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l.digestSection,
              style: TextStyle(
                  fontSize: 13,
                  color: dl.inkSoft,
                  fontWeight: FontWeight.w500)),
        ),
        SwitchListTile(
          title: Text(l.digestEnable),
          subtitle: Text(
            configured ? l.digestEnableSub : l.digestConfigureSyncFirst,
            style: TextStyle(fontSize: 12, color: dl.inkFaint),
          ),
          value: enabled,
          onChanged: (v) => _apply(context, ref, enabled: v, minutes: minutes),
        ),
        ListTile(
          enabled: enabled,
          leading: Icon(Icons.schedule_rounded, color: dl.inkSoft),
          title: Text(l.digestTime),
          trailing: Text(_fmt(minutes),
              style: TextStyle(
                  fontSize: 15,
                  color: enabled ? dl.ink : dl.inkFaint,
                  fontWeight: FontWeight.w500)),
          onTap: enabled
              ? () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: minutes ~/ 60, minute: minutes % 60),
                  );
                  if (picked != null && context.mounted) {
                    await _apply(context, ref,
                        enabled: enabled,
                        minutes: picked.hour * 60 + picked.minute);
                  }
                }
              : null,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
