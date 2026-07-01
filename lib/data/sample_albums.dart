import 'package:flutter/material.dart';

import '../models/album.dart';
import '../models/track.dart';

class SampleAlbums {
  static final beatlesOne = Album(
    id: 'beatles-1',
    title: '1 (Remastered)',
    artist: 'The Beatles',
    year: 2000,
    gradientTop: const Color(0xFF8B0000),
    gradientBottom: const Color(0xFF0A0A0A),
    tracks: const [
      Track(
        id: 'beatles-1-1',
        title: 'Love Me Do - Mono / Remastered',
        artist: 'The Beatles',
        album: '1 (Remastered)',
        filePath: '',
        duration: Duration(minutes: 2, seconds: 22),
        isDemo: true,
      ),
      Track(
        id: 'beatles-1-2',
        title: 'From Me to You - Mono / Remastered',
        artist: 'The Beatles',
        album: '1 (Remastered)',
        filePath: '',
        duration: Duration(minutes: 1, seconds: 56),
        isDemo: true,
      ),
      Track(
        id: 'beatles-1-3',
        title: 'She Loves You - Mono / Remastered',
        artist: 'The Beatles',
        album: '1 (Remastered)',
        filePath: '',
        duration: Duration(minutes: 2, seconds: 18),
        isDemo: true,
      ),
      Track(
        id: 'beatles-1-4',
        title: 'I Want To Hold Your Hand - Remastered 2015',
        artist: 'The Beatles',
        album: '1 (Remastered)',
        filePath: '',
        duration: Duration(minutes: 2, seconds: 26),
        isDemo: true,
      ),
      Track(
        id: 'beatles-1-5',
        title: 'Can\'t Buy Me Love - Remastered 2015',
        artist: 'The Beatles',
        album: '1 (Remastered)',
        filePath: '',
        duration: Duration(minutes: 2, seconds: 12),
        isDemo: true,
      ),
      Track(
        id: 'beatles-1-6',
        title: 'A Hard Day\'s Night - Remastered 2015',
        artist: 'The Beatles',
        album: '1 (Remastered)',
        filePath: '',
        duration: Duration(minutes: 2, seconds: 34),
        isDemo: true,
      ),
    ],
  );

  static List<Album> get all => [beatlesOne];

  static Album? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
