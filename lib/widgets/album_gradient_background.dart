import 'package:flutter/material.dart';

class AlbumGradientBackground extends StatelessWidget {
  final Color topColor;
  final Color bottomColor;
  final Widget child;

  const AlbumGradientBackground({
    super.key,
    required this.topColor,
    required this.bottomColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
          stops: const [0.0, 0.55],
        ),
      ),
      child: child,
    );
  }
}
