import 'package:flutter/material.dart';

class AlbumCollage extends StatelessWidget {
  const AlbumCollage({super.key});

  static const _tiles = [
    _TileSpec(0.08, 0.02, 0.28, true, Color(0xFFE13300)),
    _TileSpec(0.38, 0.0, 0.32, true, Color(0xFF1E3264)),
    _TileSpec(0.68, 0.04, 0.26, true, Color(0xFF8D67AB)),
    _TileSpec(0.02, 0.22, 0.22, false, Color(0xFFE8115B)),
    _TileSpec(0.22, 0.18, 0.30, false, Color(0xFF148A08)),
    _TileSpec(0.52, 0.16, 0.28, false, Color(0xFF477D95)),
    _TileSpec(0.78, 0.20, 0.20, false, Color(0xFFBA5D07)),
    _TileSpec(0.12, 0.42, 0.24, true, Color(0xFF509BF5)),
    _TileSpec(0.42, 0.38, 0.34, false, Color(0xFFE91429)),
    _TileSpec(0.72, 0.40, 0.22, true, Color(0xFFB49BC8)),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tile in _tiles)
                Positioned(
                  left: tile.x * w,
                  top: tile.y * h,
                  child: Transform.rotate(
                    angle: tile.isCircle ? 0 : (tile.x - 0.5) * 0.35,
                    child: Container(
                      width: tile.size * w,
                      height: tile.size * w,
                      decoration: BoxDecoration(
                        color: tile.color,
                        shape: tile.isCircle ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: tile.isCircle ? null : BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TileSpec {
  final double x;
  final double y;
  final double size;
  final bool isCircle;
  final Color color;

  const _TileSpec(this.x, this.y, this.size, this.isCircle, this.color);
}
