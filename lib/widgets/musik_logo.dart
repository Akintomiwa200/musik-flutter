import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Branded Musik logo — SVG asset with optional compact painter fallback.
class MusikLogo extends StatelessWidget {
  final double size;
  final bool useAsset;

  const MusikLogo({super.key, this.size = 48, this.useAsset = true});

  @override
  Widget build(BuildContext context) {
    if (useAsset) {
      return SvgPicture.asset(
        'assets/images/musik_logo.svg',
        width: size,
        height: size,
      );
    }
    return CustomPaint(
      size: Size(size, size),
      painter: _MusikLogoPainter(),
    );
  }
}

class MusikAppIcon extends StatelessWidget {
  final double size;

  const MusikAppIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.musikAccent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: SvgPicture.asset(
          'assets/images/musik_logo.svg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _MusikLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = AppColors.musikAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    canvas.drawArc(Rect.fromLTWH(w * 0.08, h * 0.28, w * 0.84, h * 0.5), 3.3, 2.9, false, green);
    canvas.drawArc(Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.64, h * 0.42), 3.3, 2.9, false, green);
    canvas.drawArc(Rect.fromLTWH(w * 0.28, h * 0.48, w * 0.44, h * 0.34), 3.3, 2.9, false, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


