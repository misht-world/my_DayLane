import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/db.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notifications.dart';
import 'digest_settings.dart';
import 'sync_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value;
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle,
            style: context.serif.copyWith(fontSize: 18)),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(l.settingsAutoCarry),
                  subtitle: Text(
                    l.settingsAutoCarrySubtitle,
                    style: TextStyle(fontSize: 12, color: dl.inkFaint),
                  ),
                  value: settings.autoCarry,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(autoCarry: Value(v)),
                  ),
                ),
                const Divider(height: 1),
                _sectionLabel(context, l.settingsLanguage),
                RadioGroup<String>(
                  groupValue: settings.localeCode,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(localeCode: Value(v ?? '')),
                  ),
                  child: Column(
                    children: [
                      RadioListTile(
                          value: '', title: Text(l.settingsLanguageSystem)),
                      RadioListTile(
                          value: 'ru', title: Text(l.settingsLanguageRu)),
                      RadioListTile(
                          value: 'en', title: Text(l.settingsLanguageEn)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _sectionLabel(context, l.settingsTheme),
                RadioGroup<int>(
                  groupValue: settings.themeMode,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(themeMode: Value(v ?? 0)),
                  ),
                  child: Column(
                    children: [
                      RadioListTile(
                          value: 0, title: Text(l.settingsThemeSystem)),
                      RadioListTile(
                          value: 1, title: Text(l.settingsThemeLight)),
                      RadioListTile(
                          value: 2, title: Text(l.settingsThemeDark)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _sectionLabel(context, l.settingsFirstDay),
                RadioGroup<int>(
                  groupValue: settings.firstWeekday,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(firstWeekday: Value(v ?? 1)),
                  ),
                  child: Column(
                    children: [
                      RadioListTile(
                          value: 1, title: Text(l.settingsMonday)),
                      RadioListTile(
                          value: 7, title: Text(l.settingsSunday)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      Icon(Icons.notifications_none_rounded, color: dl.inkSoft),
                  title: Text(l.settingsAllowNotifications),
                  subtitle: Text(l.settingsAllowNotificationsSubtitle,
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                  onTap: () =>
                      NotificationService.instance.requestPermissions(),
                ),
                const Divider(height: 1),
                if (kConnected) const SyncSettingsSection(),
                if (kConnected) const DigestSettingsSection(),
                _sectionLabel(context, l.settingsData),
                ListTile(
                  leading: Icon(Icons.ios_share_rounded, color: dl.inkSoft),
                  title: Text(l.settingsExport),
                  subtitle: Text(l.settingsExportSubtitle,
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                  onTap: () => _export(context, ref),
                ),
                ListTile(
                  leading: Icon(Icons.file_download_rounded, color: dl.inkSoft),
                  title: Text(l.settingsImport),
                  subtitle: Text(l.settingsImportSubtitle,
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                  onTap: () => _import(context, ref),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text('$kAppName · v$kAppVersion',
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    try {
      final file = await ref.read(backupServiceProvider).exportToFile();
      await Share.shareXFiles([XFile(file.path)], subject: l.backupSubject);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.exportFailed(e))));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = res?.files.single.path;
    if (path == null) return;
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.importQuestion),
        content: Text(l.importWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonReplace)),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final content = await File(path).readAsString();
      final n = await ref.read(backupServiceProvider).import(content);
      await ref.read(repositoryProvider).rescheduleAll();
      messenger.showSnackBar(
          SnackBar(content: Text(l.settingsImported(n))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e))));
    }
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                color: context.dl.inkSoft,
                fontWeight: FontWeight.w500)),
      );
}
