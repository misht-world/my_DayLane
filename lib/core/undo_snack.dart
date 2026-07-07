import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repository.dart';

const Duration _kUndoDuration = Duration(seconds: 5);

/// Плашка с кнопкой «Отменить» после потенциально случайных действий
/// (перенос, удаление, отложение).
void showUndoSnack(BuildContext context, String message, UndoAction undo) =>
    showUndoSnackOn(ScaffoldMessenger.of(context), message, undo);

/// Вариант с заранее захваченным messenger — для случаев, когда виджет,
/// запустивший действие, размонтируется до его завершения (строка дела
/// уходит из секции).
void showUndoSnackOn(
    ScaffoldMessengerState messenger, String message, UndoAction undo) {
  messenger.clearSnackBars();
  final controller = messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(days: 1), // ручное авто-скрытие ниже
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(label: 'Отменить', onPressed: () => undo()),
  ));
  // Свой таймер авто-скрытия: встроенный таймер SnackBar не срабатывает,
  // если на устройстве отключены/уменьшены анимации (баг Flutter) — плашка
  // тогда висит до перезапуска. Закрываем сами; повторный close() безвреден.
  Timer(_kUndoDuration, controller.close);
}
