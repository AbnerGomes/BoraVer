import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Claquete desenhada em código (usada no logotipo e no ícone do app).
class ClapperPainter extends CustomPainter {
  const ClapperPainter({
    this.body = AppColors.terracotta,
    this.stripes = AppColors.espresso,
    this.light = AppColors.cream,
  });

  final Color body;
  final Color stripes;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Radius.circular(w * 0.1);

    // Corpo
    final bodyRect = Rect.fromLTWH(0, h * 0.36, w, h * 0.64);
    canvas.drawRRect(
      RRect.fromRectAndCorners(bodyRect, bottomLeft: r, bottomRight: r),
      Paint()..color = body,
    );

    // Barra fixa e barra articulada (inclinada)
    final barHeight = h * 0.17;
    final fixedBar = Rect.fromLTWH(0, h * 0.36 - barHeight, w, barHeight);
    _stripedBar(canvas, fixedBar, r);

    canvas.save();
    canvas.translate(0, fixedBar.top);
    canvas.rotate(-0.26);
    _stripedBar(
      canvas,
      Rect.fromLTWH(0, -barHeight - h * 0.03, w, barHeight),
      r,
    );
    canvas.restore();

    // "Play" no corpo
    final cx = w * 0.5;
    final cy = h * 0.68;
    final s = w * 0.13;
    final play = Path()
      ..moveTo(cx - s * 0.8, cy - s)
      ..lineTo(cx + s * 1.1, cy)
      ..lineTo(cx - s * 0.8, cy + s)
      ..close();
    canvas.drawPath(play, Paint()..color = light);
  }

  void _stripedBar(Canvas canvas, Rect rect, Radius r) {
    final rrect = RRect.fromRectAndCorners(rect, topLeft: r, topRight: r);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..color = stripes);
    final paint = Paint()..color = light;
    final step = rect.width / 4;
    for (var x = rect.left - rect.height; x < rect.right; x += step) {
      canvas.drawPath(
        Path()
          ..moveTo(x, rect.bottom)
          ..lineTo(x + step * 0.45, rect.bottom)
          ..lineTo(x + step * 0.45 + rect.height, rect.top)
          ..lineTo(x + rect.height, rect.top)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClapperPainter oldDelegate) =>
      oldDelegate.body != body || oldDelegate.stripes != stripes;
}

/// Logotipo: claquete + nome.
class BoraVerLogo extends StatelessWidget {
  const BoraVerLogo({super.key, this.size = 32, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: ClapperPainter()),
    );
    if (!showName) return mark;
    return Semantics(
      label: 'BoraVer',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.3),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Bora'),
                TextSpan(
                  text: 'Ver',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontSize: size * 0.85,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Borda em formato de ingresso de cinema: cantos arredondados e dois
/// recortes semicirculares nas laterais.
class TicketBorder extends ShapeBorder {
  const TicketBorder({
    this.radius = AppRadius.l,
    this.notchRadius = 11,
    this.notchAt = 0.5,
    this.side = BorderSide.none,
  });

  final double radius;
  final double notchRadius;

  /// Posição vertical dos recortes (0 = topo, 1 = base).
  final double notchAt;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final y = rect.top + rect.height * notchAt;
    final notches = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius),
      );
    return Path.combine(PathOperation.difference, base, notches);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => TicketBorder(
    radius: radius * t,
    notchRadius: notchRadius * t,
    notchAt: notchAt,
    side: side.scale(t),
  );
}

/// Linha picotada horizontal, como a de um ingresso.
class PerforatedLine extends StatelessWidget {
  const PerforatedLine({super.key, this.color, this.inset = 18});

  final Color? color;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: CustomPaint(
        size: const Size(double.infinity, 1.5),
        painter: _DashPainter(color ?? AppColors.line),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    const dash = 6.0, gap = 6.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + dash, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

/// Divisória de ingresso: linha picotada com recortes semicirculares nas
/// bordas. Deve ocupar toda a largura de um cartão com recorte (clip), para
/// que os círculos da cor do fundo pareçam "mordidas" no papel — sempre
/// alinhados com a linha, qualquer que seja a altura do conteúdo.
class TicketDivider extends StatelessWidget {
  const TicketDivider({
    super.key,
    this.notchColor = AppColors.beige,
    this.lineColor,
    this.borderColor,
    this.radius = 11,
  });

  final Color notchColor;
  final Color? lineColor;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget notch() => Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: notchColor,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: radius * 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Center(
                child: PerforatedLine(color: lineColor, inset: radius + 10),
              ),
            ),
            Positioned(left: -radius, top: 0, child: notch()),
            Positioned(right: -radius, top: 0, child: notch()),
          ],
        ),
      ),
    );
  }
}

/// Fileira de perfurações de película, usada como detalhe decorativo.
class FilmStrip extends StatelessWidget {
  const FilmStrip({super.key, this.height = 14, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _FilmStripPainter(color ?? AppColors.espresso),
        ),
      ),
    );
  }
}

class _FilmStripPainter extends CustomPainter {
  const _FilmStripPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final hole = Paint()..color = AppColors.beige.withValues(alpha: 0.9);
    final holeH = size.height * 0.45;
    final holeW = holeH * 1.3;
    final step = holeW * 2.2;
    for (var x = step / 3; x < size.width; x += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - holeH) / 2, holeW, holeH),
          Radius.circular(holeH * 0.25),
        ),
        hole,
      );
    }
  }

  @override
  bool shouldRepaint(_FilmStripPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Textura suave de pontos (como a tela granulada de um cinema antigo).
class DotTexture extends StatelessWidget {
  const DotTexture({super.key, this.color, this.spacing = 14});

  final Color? color;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _DotPainter(
            color ?? AppColors.espresso.withValues(alpha: 0.05),
            spacing,
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter(this.color, this.spacing);
  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var row = 0;
    for (var y = spacing / 2; y < size.height; y += spacing, row++) {
      final offset = row.isEven ? 0.0 : spacing / 2;
      for (var x = spacing / 2 + offset; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}
