import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/links.dart';

/// Редактор списка «Ссылки и файлы»: добавить веб-ссылку или файл с телефона,
/// открыть, удалить. Работает через [links] + [onChanged] (без своего стейта),
/// поэтому подходит и карточке дела, и дневнику поездки.
class LinksEditor extends StatelessWidget {
  const LinksEditor({
    super.key,
    required this.links,
    required this.onChanged,
    this.label = 'Ссылки и файлы',
  });

  final List<String> links;
  final ValueChanged<List<String>> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: dl.inkSoft,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        for (var i = 0; i < links.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                    isWebLink(links[i])
                        ? Icons.link_rounded
                        : Icons.insert_drive_file_outlined,
                    size: 18,
                    color: dl.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => openLink(links[i]),
                    child: Text(linkLabel(links[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: dl.accent,
                            decoration: TextDecoration.underline,
                            decorationColor: dl.accent)),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: dl.inkFaint),
                  onPressed: () {
                    final next = [...links]..removeAt(i);
                    onChanged(next);
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addLink(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add_link_rounded, size: 16),
              label:
                  const Text('Добавить ссылку', style: TextStyle(fontSize: 13)),
            ),
            OutlinedButton.icon(
              onPressed: () => _addFile(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dl.lineStrong),
                foregroundColor: dl.ink,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('Файл с телефона',
                  style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addLink(BuildContext context) async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!context.mounted) return;
    final ctrl = TextEditingController(
        text: (clip != null && isWebLink(clip)) ? clip : '');
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ссылка'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
              hintText: 'https://… (Я.Диск, Google Drive, любая)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Добавить')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) onChanged([...links, url]);
  }

  Future<void> _addFile(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles();
    final path = res?.files.single.path;
    if (path == null) return;
    try {
      final stored = await importFileToAppStorage(path);
      onChanged([...links, stored]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось прикрепить файл: $e')));
      }
    }
  }
}
