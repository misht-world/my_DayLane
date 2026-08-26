import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/sync_providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sync_config.dart';
import '../../services/sync_transport.dart';

/// Секция настроек синхронизации (только в connected-редакции): поле
/// «репозиторий», токен (в защищённом хранилище) и запуск синхронизации.
class SyncSettingsSection extends ConsumerStatefulWidget {
  const SyncSettingsSection({super.key});

  @override
  ConsumerState<SyncSettingsSection> createState() =>
      _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends ConsumerState<SyncSettingsSection> {
  final _repo = TextEditingController();
  final _token = TextEditingController();
  bool _prefilled = false;
  bool _obscure = true;

  @override
  void dispose() {
    _repo.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final (owner, repo) = SyncConfig.parseRepoPath(_repo.text);
    final cfg = ref.read(syncControllerProvider).config.copyWith(
          owner: owner,
          repo: repo,
          token: _token.text.trim(),
        );
    await ref.read(syncControllerProvider.notifier).saveConfig(cfg);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.syncSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final st = ref.watch(syncControllerProvider);

    if (st.loaded && !_prefilled) {
      _repo.text = st.config.repoPath;
      _token.text = st.config.token;
      _prefilled = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l.syncSection,
              style: TextStyle(
                  fontSize: 13,
                  color: dl.inkSoft,
                  fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(l.syncHint,
              style: TextStyle(fontSize: 12, color: dl.inkFaint)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _repo,
            decoration: InputDecoration(
              labelText: l.syncRepo,
              hintText: l.syncRepoHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _token,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.syncToken,
              hintText: 'github_pat_…',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: st.phase == SyncPhase.syncing ? null : _sync,
                icon: st.phase == SyncPhase.syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(l.syncNow),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _save, child: Text(l.commonSave)),
              const Spacer(),
              if (st.config.isComplete)
                IconButton(
                  tooltip: l.syncDisconnect,
                  icon: Icon(Icons.link_off_rounded, color: dl.inkSoft),
                  onPressed: _disconnect,
                ),
            ],
          ),
        ),
        _statusLine(context, l, st),
        const Divider(height: 24),
      ],
    );
  }

  Future<void> _sync() async {
    await _save();
    await ref.read(syncControllerProvider.notifier).syncNow();
  }

  Future<void> _disconnect() async {
    await ref.read(syncControllerProvider.notifier).disconnect();
    _repo.clear();
    _token.clear();
  }

  String _errText(AppLocalizations l, SyncErrorKind k) => switch (k) {
        SyncErrorKind.network => l.syncErrNetwork,
        SyncErrorKind.auth => l.syncErrAuth,
        SyncErrorKind.read => l.syncErrRead,
        SyncErrorKind.write => l.syncErrWrite,
        SyncErrorKind.conflict => l.syncErrOther,
        SyncErrorKind.other => l.syncErrOther,
      };

  String _statusText(AppLocalizations l, SyncUiState st) {
    switch (st.phase) {
      case SyncPhase.syncing:
        return '…';
      case SyncPhase.error:
        return st.errorKind == null
            ? l.syncFillRepoToken
            : _errText(l, st.errorKind!);
      case SyncPhase.ok:
        final r = st.result;
        final parts = <String>[
          if (r != null && !r.changedLocally && !r.pushedRemote)
            l.syncUpToDate
          else if (r != null) ...[
            if (r.applied > 0) '↓ ${r.applied}',
            if (r.deleted > 0) '− ${r.deleted}',
            if (r.pushed > 0) '↑ ${r.pushed}',
          ],
          if (st.lastSyncAt != null)
            l.syncUpdatedAt(DateFormat('HH:mm').format(st.lastSyncAt!)),
        ];
        return parts.isEmpty ? l.syncReady : parts.join(' · ');
      case SyncPhase.idle:
        return st.config.isComplete ? l.syncReady : l.syncNotConfigured;
    }
  }

  Widget _statusLine(
      BuildContext context, AppLocalizations l, SyncUiState st) {
    final dl = context.dl;
    final (IconData icon, Color color) = switch (st.phase) {
      SyncPhase.ok => (Icons.check_circle_rounded, dl.accent),
      SyncPhase.error => (Icons.error_outline_rounded, dl.danger),
      SyncPhase.syncing => (Icons.sync_rounded, dl.inkSoft),
      SyncPhase.idle => (Icons.cloud_off_rounded, dl.inkFaint),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_statusText(l, st),
                style: TextStyle(fontSize: 12, color: dl.inkFaint)),
          ),
        ],
      ),
    );
  }
}
