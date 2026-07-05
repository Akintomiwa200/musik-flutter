import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/usb_music_service.dart';
import '../theme/app_theme.dart';
import '../widgets/track_tile.dart';

class UsbScreen extends StatefulWidget {
  const UsbScreen({super.key});

  @override
  State<UsbScreen> createState() => _UsbScreenState();
}

class _UsbScreenState extends State<UsbScreen> {
  final _usbService = UsbMusicService();
  List<UsbDeviceInfo> _devices = [];
  List<Track> _tracks = [];
  String? _selectedPath;
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _scanUsb();
  }

  Future<void> _scanUsb() async {
    setState(() {
      _loading = true;
      _status = null;
    });
    await _usbService.requestPermissions();
    final devices = await _usbService.scanUsbDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _loading = false;
        if (devices.isEmpty) {
          _status = 'No USB storage detected. Connect a drive via OTG or pick a folder manually.';
        }
      });
    }
  }

  Future<void> _pickFolder() async {
    setState(() => _loading = true);
    final path = await _usbService.pickUsbFolder();
    if (path != null) {
      final tracks = await _usbService.scanDirectory(path, source: 'usb');
      if (mounted) {
        setState(() {
          _selectedPath = path;
          _tracks = tracks;
          _loading = false;
          _status = tracks.isEmpty ? 'No audio files found in selected folder.' : null;
        });
      }
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDevice(UsbDeviceInfo device) async {
    setState(() {
      _loading = true;
      _selectedPath = device.path;
    });
    final tracks = await _usbService.scanDirectory(device.path, source: 'usb');
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Music'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _scanUsb),
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _pickFolder),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_status != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_status!, style: TextStyle(color: context.textSecondary)),
                  ),
                if (_devices.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Detected devices', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  SizedBox(
                    height: 56,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _devices.length,
                      itemBuilder: (_, i) {
                        final d = _devices[i];
                        final selected = _selectedPath == d.path;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text('${d.name} (${d.trackCount})'),
                            selected: selected,
                            selectedColor: AppColors.musikAccent.withValues(alpha: 0.3),
                            onSelected: (_) => _loadDevice(d),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        _tracks.isEmpty ? 'Tracks' : '${_tracks.length} tracks',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const Spacer(),
                      if (_tracks.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => player.playTrack(_tracks.first, queue: _tracks, index: 0),
                          icon: const Icon(Icons.play_arrow, color: AppColors.musikAccent),
                          label: const Text('Play all', style: TextStyle(color: AppColors.musikAccent)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tracks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.usb_off, size: 64, color: context.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text('No USB tracks loaded'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _pickFolder,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Browse folder'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tracks.length,
                          itemBuilder: (_, i) {
                            final track = _tracks[i];
                            final isPlaying = player.currentTrack?.id == track.id && player.isPlaying;
                            return TrackTile(
                              track: track,
                              index: i + 1,
                              isPlaying: isPlaying,
                              onTap: () => player.playTrack(track, queue: _tracks, index: i),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFolder,
        icon: const Icon(Icons.usb),
        label: const Text('USB / Folder'),
      ),
    );
  }
}


