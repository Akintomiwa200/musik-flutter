import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/track.dart';

class UsbMusicService {
  static const _audioExtensions = {'.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma'};

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.storage,
      Permission.audio,
      Permission.manageExternalStorage,
    ].request();

    return statuses.values.any((s) => s.isGranted);
  }

  /// Pick a USB / external storage folder via system file picker (SAF).
  Future<String?> pickUsbFolder() async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select USB or music folder',
    );
    return result;
  }

  /// Scan common Android external / OTG mount points.
  Future<List<UsbDeviceInfo>> scanUsbDevices() async {
    if (!Platform.isAndroid) return [];

    final devices = <UsbDeviceInfo>[];
    final seen = <String>{};

    final roots = <String>[
      '/storage',
      '/mnt/media_rw',
      '/mnt/usb',
      '/mnt/usbhost',
    ];

    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;

      try {
        for (final entity in dir.listSync()) {
          if (entity is! Directory) continue;
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name == 'emulated' || name == 'self') continue;
          if (seen.contains(entity.path)) continue;
          seen.add(entity.path);

          final tracks = await scanDirectory(entity.path, source: 'usb');
          if (tracks.isNotEmpty) {
            devices.add(UsbDeviceInfo(
              name: name,
              path: entity.path,
              trackCount: tracks.length,
            ));
          }
        }
      } catch (_) {}
    }

    return devices;
  }

  Future<List<Track>> scanDirectory(String path, {String source = 'local'}) async {
    final tracks = <Track>[];
    final dir = Directory(path);
    if (!dir.existsSync()) return tracks;

    await _scanRecursive(dir, tracks, source);
    tracks.sort((a, b) => a.title.compareTo(b.title));
    return tracks;
  }

  Future<void> _scanRecursive(Directory dir, List<Track> tracks, String source) async {
    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final ext = _extension(entity.path);
          if (_audioExtensions.contains(ext)) {
            tracks.add(_fileToTrack(entity, source));
          }
        } else if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (!name.startsWith('.')) {
            await _scanRecursive(entity, tracks, source);
          }
        }
      }
    } catch (_) {}
  }

  Track _fileToTrack(File file, String source) {
    final name = file.path.split(Platform.pathSeparator).last;
    final title = name.replaceAll(RegExp(r'\.[^.]+$'), '');
    return Track(
      id: file.path,
      title: title,
      artist: 'Unknown Artist',
      album: 'USB Library',
      filePath: file.path,
      source: source,
    );
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '';
    return path.substring(dot).toLowerCase();
  }

  Future<List<Track>> scanLocalMusic() async {
    if (!Platform.isAndroid) return [];

    final paths = <String>[
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
    ];

    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) paths.add(ext.path);
    } catch (_) {}

    final all = <Track>[];
    for (final p in paths) {
      all.addAll(await scanDirectory(p, source: 'local'));
    }
    return all;
  }
}
