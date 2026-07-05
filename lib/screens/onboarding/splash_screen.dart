import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: const _AuthMark(size: 74),
        ),
      ),
    );
  }
}

class AuthLogo extends StatelessWidget {
  final double markSize;

  const AuthLogo({super.key, this.markSize = 42});

  @override
  Widget build(BuildContext context) {
    return _AuthMark(size: markSize);
  }
}

class _AuthMark extends StatelessWidget {
  final double size;

  const _AuthMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AuthMarkPainter()),
    );
  }
}

class _AuthMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      const Color(0xFF64C7FF),
      AppColors.musikAccent,
      const Color(0xFF087DFF),
    ];
    for (var i = 0; i < 3; i++) {
      paint.color = colors[i];
      final top = size.height * (0.18 + i * 0.18);
      final path = Path()
        ..moveTo(size.width * 0.18, top)
        ..lineTo(size.width * 0.76, top + size.height * 0.16)
        ..lineTo(size.width * 0.76, top + size.height * 0.28)
        ..lineTo(size.width * 0.18, top + size.height * 0.12)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
