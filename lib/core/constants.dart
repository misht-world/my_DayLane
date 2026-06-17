import 'package:flutter/material.dart';

/// Имя продукта. Менять здесь — переименование тривиально.
const String kAppName = 'DayLane';

/// Версия приложения (синхронизировать с `version:` в pubspec.yaml).
const String kAppVersion = '1.0.0';

/// Фиксированная палитра цветов дел. `colorId` — индекс в этом списке.
/// Цвета подобраны так, чтобы читаться и в светлой, и в тёмной теме.
class TaskPalette {
  TaskPalette._();

  static const Color blue = Color(0xFF378ADD);
  static const Color green = Color(0xFF1D9E75);
  static const Color amber = Color(0xFFBA7517);
  static const Color purple = Color(0xFF534AB7);
  static const Color pink = Color(0xFFD4537E);
  static const Color gray = Color(0xFF888780);

  static const List<Color> colors = [blue, green, amber, purple, pink, gray];

  static const List<String> names = [
    'Синий',
    'Зелёный',
    'Янтарный',
    'Фиолетовый',
    'Розовый',
    'Серый',
  ];

  static const int defaultColorId = 0;

  static Color byId(int id) => colors[id % colors.length];
}

/// Дефолтное время напоминания — 09:00 (в минутах от полуночи).
const int kDefaultReminderMinutes = 9 * 60;
