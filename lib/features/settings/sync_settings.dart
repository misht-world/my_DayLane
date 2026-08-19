import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/sync_providers.dart';
import '../../core/theme.dart';
import '../../services/sync_config.dart';

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
    final (owner, repo) = SyncConfig.parseRepoPath(_repo.text);
    final cfg = ref.read(syncControllerProvider).config.copyWith(
          owner: owner,
          repo: repo,
          token: _token.text.trim(),
        );
    await ref.read(syncControllerProvider.notifier).saveConfig(cfg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки синхронизации сохранены')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final st = ref.watch(syncControllerProvider);

    // Один раз подставляем сохранённые значения в поля.
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
          child: Text('Синхронизация',
              style: TextStyle(
                  fontSize: 13,
                  color: dl.inkSoft,
                  fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Приватный GitHub-репозиторий как «облако» между устройствами. '
            'Токен хранится в защищённом хранилище устройства.',
            style: TextStyle(fontSize: 12, color: dl.inkFaint),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _repo,
            decoration: const InputDecoration(
              labelText: 'Репозиторий',
              hintText: 'логин/daylane-sync',
              border: OutlineInputBorder(),
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
              labelText: 'Токен (fine-grained PAT)',
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
                onPressed:
                    st.phase == SyncPhase.syncing ? null : () => _sync(),
                icon: st.phase == SyncPhase.syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Синхронизировать'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: _save, child: const Text('Сохранить')),
              const Spacer(),
              if (st.config.isComplete)
                IconButton(
                  tooltip: 'Отключить',
                  icon: Icon(Icons.link_off_rounded, color: dl.inkSoft),
                  onPressed: _disconnect,
                ),
            ],
          ),
        ),
        _statusLine(context, st),
        const Divider(height: 24),
      ],
    );
  }

  Future<void> _sync() async {
    // Сохраняем то, что в полях, и сразу синхронизируем.
    await _save();
    await ref.read(syncControllerProvider.notifier).syncNow();
  }

  Future<void> _disconnect() async {
    await ref.read(syncControllerProvider.notifier).disconnect();
    _repo.clear();
    _token.clear();
  }

  Widget _statusLine(BuildContext context, SyncUiState st) {
    final dl = context.dl;
    final (IconData icon, Color color) = switch (st.phase) {
      SyncPhase.ok => (Icons.check_circle_rounded, dl.accent),
      SyncPhase.error => (Icons.error_outline_rounded, dl.danger),
      SyncPhase.syncing => (Icons.sync_rounded, dl.inkSoft),
      SyncPhase.idle => (Icons.cloud_off_rounded, dl.inkFaint),
    };
    final parts = <String>[
      if (st.message != null) st.message!,
      if (st.lastSyncAt != null)
        'обновлено в ${DateFormat('HH:mm').format(st.lastSyncAt!)}',
    ];
    final text = parts.isEmpty
        ? (st.config.isComplete ? 'Готово к синхронизации' : 'Не настроено')
        : parts.join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: dl.inkFaint)),
          ),
        ],
      ),
    );
  }
}
