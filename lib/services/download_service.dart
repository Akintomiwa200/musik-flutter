import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';
import 'stream_resolver_service.dart';

enum DownloadStatus { none, downloading, completed, failed }

class DownloadTask {
  final Track track;
  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final String? error;

  const DownloadTask({
    required this.track,
    this.status = DownloadStatus.none,
    this.progress = 0,
    this.localPath,
    this.error,
  });
}

class DownloadService extends ChangeNotifier {
  final StreamResolverService _resolver;
  final Map<String, DownloadTask> _tasks = {};
  String? _downloadDir;

  DownloadService(this._resolver);

  DownloadTask? taskFor(String trackId) => _tasks[trackId];
  bool isDownloaded(String trackId) =>
      _tasks[trackId]?.status == DownloadStatus.completed;
  String? localPathFor(String trackId) => _tasks[trackId]?.localPath;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _downloadDir = '${dir.path}/downloads';
    final d = Directory(_downloadDir!);
    if (!await d.exists()) await d.create(recursive: true);
    _restoreFromDisk();
  }

  void _restoreFromDisk() {
    if (_downloadDir == null) return;
    final d = Directory(_downloadDir!);
    if (!d.existsSync()) return;
    for (final f in d.listSync()) {
      if (f is File && f.path.endsWith('.mp3')) {
        final name = f.uri.pathSegments.last;
        final id = name.replaceAll(RegExp(r'\.mp3$'), '');
        _tasks[id] = DownloadTask(
          track: Track(id: id, title: name, artist: ''),
          status: DownloadStatus.completed,
          localPath: f.path,
        );
      }
    }
  }

  Future<void> download(Track track) async {
    if (_tasks[track.id]?.status == DownloadStatus.downloading) return;
    if (_tasks[track.id]?.status == DownloadStatus.completed) return;

    _tasks[track.id] = DownloadTask(track: track, status: DownloadStatus.downloading);
    notifyListeners();

    try {
      final resolved = await _resolver.resolve(track);
      final uri = Uri.parse(resolved.url);
      final response = await http.Client().send(http.Request('GET', uri));

      if (response.statusCode != 200) {
        throw HttpException('Server returned ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final filePath = '$_downloadDir/${_safeFileName(track)}.mp3';
      final file = File(filePath);
      final sink = file.openWrite();
      var downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          _tasks[track.id] = DownloadTask(
            track: track,
            status: DownloadStatus.downloading,
            progress: downloaded / contentLength,
          );
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();

      final enriched = track.copyWith(
        filePath: filePath,
        source: 'local',
        streamUrl: null,
        previewUrl: null,
      );

      _tasks[track.id] = DownloadTask(
        track: enriched,
        status: DownloadStatus.completed,
        progress: 1,
        localPath: filePath,
      );
      notifyListeners();
    } catch (e) {
      _tasks[track.id] = DownloadTask(
        track: track,
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteDownload(String trackId) async {
    final task = _tasks[trackId];
    if (task?.localPath != null) {
      await File(task!.localPath!).delete();
    }
    _tasks.remove(trackId);
    notifyListeners();
  }

  String _safeFileName(Track track) {
    final name = '${track.artist} - ${track.title}'
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '$name-${track.id}';
  }

  Future<void> clearDownloads() async {
    if (_downloadDir == null) return;
    final d = Directory(_downloadDir!);
    if (await d.exists()) await d.delete(recursive: true);
    _tasks.clear();
    notifyListeners();
  }
}
