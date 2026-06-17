import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../data/seed.dart';
import '../features/home/home_screen.dart';
import 'providers.dart';

class DayLaneApp extends ConsumerStatefulWidget {
  const DayLaneApp({super.key});

  @override
  ConsumerState<DayLaneApp> createState() => _DayLaneAppState();
}

class _DayLaneAppState extends ConsumerState<DayLaneApp> {
  bool _maintenanceDone = false;

  @override
  Widget build(BuildContext context) {
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

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
