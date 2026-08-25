import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../data/seed.dart';
import '../features/home/home_screen.dart';
import 'providers.dart';
import 'sync_providers.dart';

class DayLaneApp extends ConsumerStatefulWidget {
  const DayLaneApp({super.key});

  @override
  ConsumerState<DayLaneApp> createState() => _DayLaneAppState();
}

class _DayLaneAppState extends ConsumerState<DayLaneApp> {
  bool _maintenanceDone = false;

  @override
  Widget build(BuildContext context) {
    // Держим контроллер синхронизации живым с запуска приложения (иначе он
    // создавался бы лениво только при открытии Настроек — и авто-синк/таймер/
    // жизненный цикл не работали бы до захода туда). listen — без перерисовок.
    if (kConnected) {
      ref.listen(syncControllerProvider, (_, _) {});
    }

    // Однократное стартовое обслуживание после загрузки настроек.
    ref.listen(settingsProvider, (_, next) {
      final s = next.value;
      if (s != null && !_maintenanceDone) {
        _maintenanceDone = true;
        final repo = ref.read(repositoryProvider);
        Future(() async {
          if (kDebugMode) {
            await seedIfEmpty(ref.read(databaseProvider), repo);
          }
          await repo.runStartupMaintenance(autoCarry: s.autoCarry);
        });
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // null → следовать системному языку среди поддерживаемых.
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Форматирование дат (intl DateFormat без явной локали) следует за языком
      // приложения — задаём глобальную локаль intl из разрешённой локали.
      builder: (context, child) {
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
        return child ?? const SizedBox.shrink();
      },
      home: const HomeScreen(),
    );
  }
}
