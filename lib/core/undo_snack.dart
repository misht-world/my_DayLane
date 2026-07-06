import 'package:flutter/material.dart';

import '../data/repository.dart';

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
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 5),
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(label: 'Отменить', onPressed: () => undo()),
  ));
}
