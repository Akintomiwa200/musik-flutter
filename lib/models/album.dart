import 'package:flutter/material.dart';

import '../models/track.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final int year;
  final Color gradientTop;
  final Color gradientBottom;
  final List<Track> tracks;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.gradientTop,
    required this.gradientBottom,
    required this.tracks,
  });

  String get subtitle => 'Album • $year';
}

class SheetAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const SheetAction({required this.label, required this.icon, this.onTap});
}
