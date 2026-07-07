import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  Intl.defaultLocale = 'ru';
  // Запускаем UI сразу; уведомления инициализируем в фоне, чтобы их сбой
  // не подвешивал старт (чёрный экран/логотип).
  runApp(const ProviderScope(child: DayLaneApp()));
  unawaited(NotificationService.instance.init());
}
