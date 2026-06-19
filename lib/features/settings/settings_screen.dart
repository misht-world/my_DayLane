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
import '../../services/notifications.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = context.dl;
    final settings = ref.watch(settingsProvider).value;
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки', style: context.serif.copyWith(fontSize: 18)),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Автоперенос невыполненного'),
                  subtitle: Text(
                    'При запуске переносить просроченные однодневные дела на сегодня',
                    style: TextStyle(fontSize: 12, color: dl.inkFaint),
                  ),
                  value: settings.autoCarry,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(autoCarry: Value(v)),
                  ),
                ),
                const Divider(height: 1),
                _sectionLabel(context, 'Тема'),
                RadioGroup<int>(
                  groupValue: settings.themeMode,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(themeMode: Value(v ?? 0)),
                  ),
                  child: const Column(
                    children: [
                      RadioListTile(value: 0, title: Text('Системная')),
                      RadioListTile(value: 1, title: Text('Светлая')),
                      RadioListTile(value: 2, title: Text('Тёмная')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _sectionLabel(context, 'Первый день недели'),
                RadioGroup<int>(
                  groupValue: settings.firstWeekday,
                  onChanged: (v) => db.updateSettings(
                    AppSettingsCompanion(firstWeekday: Value(v ?? 1)),
                  ),
                  child: const Column(
                    children: [
                      RadioListTile(value: 1, title: Text('Понедельник')),
                      RadioListTile(value: 7, title: Text('Воскресенье')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: dl.inkSoft),
                  title: const Text('Разрешить уведомления'),
                  subtitle: Text('Нужно для напоминаний',
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                  onTap: () =>
                      NotificationService.instance.requestPermissions(),
                ),
                const Divider(height: 1),
                _sectionLabel(context, 'Данные'),
                ListTile(
                  leading: Icon(Icons.ios_share, color: dl.inkSoft),
                  title: const Text('Экспорт (резервная копия)'),
                  subtitle: Text('Сохранить все дела в файл JSON',
                      style: TextStyle(fontSize: 12, color: dl.inkFaint)),
                  onTap: () => _export(context, ref),
                ),
                ListTile(
                  leading: Icon(Icons.file_download_outlined, color: dl.inkSoft),
                  title: const Text('Импорт из файла'),
                  subtitle: Text('Заменить все данные из резервной копии',
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
    try {
      final file = await ref.read(backupServiceProvider).exportToFile();
      await Share.shareXFiles([XFile(file.path)],
          subject: 'DayLane — резервная копия');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Не удалось: $e')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
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
        title: const Text('Импортировать?'),
        content: const Text(
            'Все текущие дела будут заменены данными из файла. Действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Заменить')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final content = await File(path).readAsString();
      final n = await ref.read(backupServiceProvider).import(content);
      await ref.read(repositoryProvider).rescheduleAll();
      messenger.showSnackBar(
          SnackBar(content: Text('Импортировано дел: $n')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Ошибка импорта: $e')));
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
