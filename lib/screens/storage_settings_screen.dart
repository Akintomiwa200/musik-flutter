import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/apk_update_service.dart';
import '../theme/app_theme.dart';
import 'usb_screen.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  final _apkService = ApkUpdateService();
  final _urlController = TextEditingController();
  String _version = '';
  ApkUpdateInfo? _pendingUpdate;
  bool _checking = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    final url = await _apkService.getUpdateManifestUrl();
    if (mounted) {
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
        _urlController.text = url;
      });
    }
  }

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    final update = await _apkService.checkForUpdate();
    if (mounted) {
      setState(() {
        _checking = false;
        _pendingUpdate = update;
      });
      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the latest version')),
        );
      }
    }
  }

  Future<void> _downloadAndInstall() async {
    final update = _pendingUpdate;
    if (update == null || update.downloadUrl.isEmpty) return;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    final path = await _apkService.downloadApk(update.downloadUrl, (p) {
      if (mounted) setState(() => _downloadProgress = p);
    });
    if (mounted) {
      setState(() => _downloading = false);
      if (path != null) {
        await _apkService.installApk(path);
      } else {
        await _apkService.openDownloadPage(update.downloadUrl);
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            tileColor: context.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: const Icon(Icons.usb),
            title: const Text('USB Music'),
            subtitle: const Text('Browse music from USB OTG drives'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UsbScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('App version', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_version),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'APK update manifest URL',
              filled: true,
              fillColor: context.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checking ? null : _checkUpdate,
                  child: Text(_checking ? 'Checking...' : 'Check for updates'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await _apkService.setUpdateManifestUrl(_urlController.text.trim());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Update URL saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          if (_pendingUpdate != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _downloading ? null : _downloadAndInstall,
              icon: const Icon(Icons.download),
              label: Text(_downloading
                  ? '${(_downloadProgress * 100).toStringAsFixed(0)}%'
                  : 'Download APK v${_pendingUpdate!.version}'),
            ),
          ],
        ],
      ),
    );
  }
}


