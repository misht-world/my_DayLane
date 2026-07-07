import 'package:flutter/material.dart';

import 'theme.dart';

/// Заголовок, подсвеченный «текстовыделителем»: за словом — мазок маркера,
/// накрывающий нижнюю часть букв (как настоящий выделитель в ежедневнике),
/// с лёгким наклоном и «залезанием» за края. Сам текст — крупный серифный
/// курсив поверх.
class MarkerLabel extends StatelessWidget {
  const MarkerLabel({
    super.key,
    required this.text,
    this.fontSize = 20,
    this.markerColor,
    this.alpha = 0.55,
    this.stretchWidth,
  });

  final String text;
  final double fontSize;

  /// Цвет маркера; по умолчанию — жёлтый выделитель темы.
  final Color? markerColor;

  /// Насыщенность мазка (раскрытая секция — сильнее, свёрнутая — бледнее).
  final double alpha;

  /// Если задано — мазок тянется на эту ширину (от начала), а не по слову.
  /// Толщина и наклон подгоняются так, чтобы визуально совпадать с коротким.
  final double? stretchWidth;

  @override
  Widget build(BuildContext context) {
    final dl = context.dl;
    final color = (markerColor ?? dl.marker).withValues(alpha: alpha);
    final stretched = stretchWidth != null;
    // Наклон даёт фиксированный подъём ~1.8px независимо от длины мазка —
    // на длинном штрихе тот же угол выглядел бы «съезжающим».
    final angle = stretched ? (-1.8 / stretchWidth!).clamp(-0.012, 0.0) : -0.012;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Мазок по нижней части букв: сверху отступ ~половина кегля, снизу —
        // чуть ниже базовой линии; края выходят за текст.
        Positioned(
          left: -4,
          right: stretched ? null : -6,
          width: stretchWidth,
          top: fontSize * 0.52,
          bottom: fontSize * 0.02,
          child: Transform.rotate(
            angle: angle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            text,
            style: context.serif.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: dl.ink,
            ),
          ),
        ),
      ],
    );
  }
}
