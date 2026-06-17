import 'package:flutter/material.dart';

/// Темы DayLane.
///
/// Светлая — тёплый «ежедневник»: off-white бумага, янтарный акцент,
/// разлиновка вместо рамок. Тёмная — спокойный нейтральный dark с той же
/// структурой, но без имитации бумаги и с более яркими цветами.
///
/// Serif используется для дат и заголовков секций. На Android семейство
/// `serif` резолвится системой (Noto Serif), отдельный шрифт не бандлим.
class AppTheme {
  AppTheme._();

  static const String serifFamily = 'serif';

  // ── Светлая палитра («Журнал») ──────────────────────────────────
  static const Color _lAccent = Color(0xFFB45309); // тёплый терракот-янтарь
  static const Color _lPage = Color(0xFFFBF9F4);
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lSunken = Color(0xFFF3EFE5);
  static const Color _lInk = Color(0xFF1A160F);
  static const Color _lInkSoft = Color(0xFF6E695B);
  static const Color _lInkFaint = Color(0xFFB5AF9F);
  static const Color _lLine = Color(0xFFEBE6DA);
  static const Color _lLineStrong = Color(0xFFDDD7C8);
  static const Color _lDanger = Color(0xFFB0392B);

  // ── Тёмная палитра («Журнал») ───────────────────────────────────
  static const Color _dAccent = Color(0xFFE0A33A);
  static const Color _dPage = Color(0xFF100F0B);
  static const Color _dSurface = Color(0xFF16140F);
  static const Color _dSunken = Color(0xFF1E1B14);
  static const Color _dInk = Color(0xFFEFE9DC);
  static const Color _dInkSoft = Color(0xFF9A9282);
  static const Color _dInkFaint = Color(0xFF7D766A);
  static const Color _dLine = Color(0xFF262219);
  static const Color _dLineStrong = Color(0xFF34301F);
  static const Color _dDanger = Color(0xFFF09B8C);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        accent: _lAccent,
        onAccent: Colors.white,
        page: _lPage,
        surface: _lSurface,
        sunken: _lSunken,
        ink: _lInk,
        inkSoft: _lInkSoft,
        inkFaint: _lInkFaint,
        line: _lLine,
        lineStrong: _lLineStrong,
        danger: _lDanger,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        accent: _dAccent,
        onAccent: const Color(0xFF2E2516),
        page: _dPage,
        surface: _dSurface,
        sunken: _dSunken,
        ink: _dInk,
        inkSoft: _dInkSoft,
        inkFaint: _dInkFaint,
        line: _dLine,
        lineStrong: _dLineStrong,
        danger: _dDanger,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color accent,
    required Color onAccent,
    required Color page,
    required Color surface,
    required Color sunken,
    required Color ink,
    required Color inkSoft,
    required Color inkFaint,
    required Color line,
    required Color lineStrong,
    required Color danger,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF0C0B08),
      surfaceContainerLow: sunken,
      surfaceContainer: page,
      surfaceContainerHigh: sunken,
      onSurfaceVariant: inkSoft,
      outline: lineStrong,
      outlineVariant: line,
      error: danger,
      onError: brightness == Brightness.light ? Colors.white : const Color(0xFF4B1414),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: page,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      iconTheme: IconThemeData(color: inkSoft),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: line),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: line),
        backgroundColor: sunken,
      ),
      extensions: [
        DayLaneColors(
          page: page,
          surface: surface,
          sunken: sunken,
          ink: ink,
          inkSoft: inkSoft,
          inkFaint: inkFaint,
          line: line,
          lineStrong: lineStrong,
          accent: accent,
          danger: danger,
          // Две задачные краски: однодневные — синий, многодневные — янтарь.
          taskSingle: brightness == Brightness.light
              ? const Color(0xFF2F6FED)
              : const Color(0xFF5AA2F0),
          taskPeriod: accent,
        ),
      ],
    );
  }
}

/// Доп. цвета вне ColorScheme — удобный доступ через `context`.
@immutable
class DayLaneColors extends ThemeExtension<DayLaneColors> {
  final Color page;
  final Color surface;
  final Color sunken;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color line;
  final Color lineStrong;
  final Color accent;
  final Color danger;

  /// Цвет однодневных дел.
  final Color taskSingle;

  /// Цвет многодневных дел (периодов).
  final Color taskPeriod;

  const DayLaneColors({
    required this.page,
    required this.surface,
    required this.sunken,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.danger,
    required this.taskSingle,
    required this.taskPeriod,
  });

  @override
  DayLaneColors copyWith({
    Color? page,
    Color? surface,
    Color? sunken,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? danger,
    Color? taskSingle,
    Color? taskPeriod,
  }) {
    return DayLaneColors(
      page: page ?? this.page,
      surface: surface ?? this.surface,
      sunken: sunken ?? this.sunken,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      accent: accent ?? this.accent,
      danger: danger ?? this.danger,
      taskSingle: taskSingle ?? this.taskSingle,
      taskPeriod: taskPeriod ?? this.taskPeriod,
    );
  }

  @override
  DayLaneColors lerp(DayLaneColors? other, double t) {
    if (other == null) return this;
    return DayLaneColors(
      page: Color.lerp(page, other.page, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      sunken: Color.lerp(sunken, other.sunken, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      taskSingle: Color.lerp(taskSingle, other.taskSingle, t)!,
      taskPeriod: Color.lerp(taskPeriod, other.taskPeriod, t)!,
    );
  }
}

/// Быстрый доступ: `context.dl`.
extension DayLaneColorsX on BuildContext {
  DayLaneColors get dl => Theme.of(this).extension<DayLaneColors>()!;
  TextStyle get serif => TextStyle(fontFamily: AppTheme.serifFamily);
}
