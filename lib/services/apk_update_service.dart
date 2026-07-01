import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ApkUpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;

  const ApkUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory ApkUpdateInfo.fromJson(Map<String, dynamic> json) {
    return ApkUpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['build_number'] as int? ?? 1,
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
    );
  }
}

class ApkUpdateService {
  static const _prefsKey = 'apk_update_url';
  static const defaultUpdateManifestUrl =
      'https://raw.githubusercontent.com/your-org/musik/main/releases/latest.json';

  Future<String> getUpdateManifestUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? defaultUpdateManifestUrl;
  }

  Future<void> setUpdateManifestUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
  }

  Future<ApkUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      final manifestUrl = await getUpdateManifestUrl();
      final response = await http.get(Uri.parse(manifestUrl)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) return null;

      final info = ApkUpdateInfo.fromJson(
        _parseJson(response.body),
      );

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      if (info.buildNumber > currentBuild) {
        return info;
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  Map<String, dynamic> _parseJson(String body) {
    // Minimal JSON parse without dart:convert dependency issues
    final map = <String, dynamic>{};
    final versionMatch = RegExp(r'"version"\s*:\s*"([^"]+)"').firstMatch(body);
    final buildMatch = RegExp(r'"build_number"\s*:\s*(\d+)').firstMatch(body);
    final urlMatch = RegExp(r'"download_url"\s*:\s*"([^"]+)"').firstMatch(body);
    final notesMatch = RegExp(r'"release_notes"\s*:\s*"([^"]*)"').firstMatch(body);

    if (versionMatch != null) map['version'] = versionMatch.group(1);
    if (buildMatch != null) map['build_number'] = int.parse(buildMatch.group(1)!);
    if (urlMatch != null) map['download_url'] = urlMatch.group(1);
    if (notesMatch != null) map['release_notes'] = notesMatch.group(1);
    return map;
  }

  /// Download APK to app cache and return local file path.
  Future<String?> downloadApk(String url, void Function(double progress) onProgress) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) return null;

      final total = response.contentLength ?? 0;
      var received = 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }

      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final file = File('${dir.path}/musik_update.apk');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('APK download failed: $e');
      return null;
    }
  }

  Future<bool> installApk(String filePath) async {
    final uri = Uri.parse('file://$filePath');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openDownloadPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
