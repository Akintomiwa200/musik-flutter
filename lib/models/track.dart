class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration? duration;
  final String source;
  final bool isDemo;
  final String? previewUrl;
  final String? streamUrl;
  final String? coverUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.filePath = '',
    this.duration,
    this.source = 'local',
    this.isDemo = false,
    this.previewUrl,
    this.streamUrl,
    this.coverUrl,
  });

  bool get isRemoteCatalog => source == 'deezer' || (previewUrl != null && previewUrl!.isNotEmpty);
  bool get isStream => streamUrl != null && streamUrl!.isNotEmpty || previewUrl != null && previewUrl!.isNotEmpty;
  bool get hasLocalFile => filePath.isNotEmpty && !isDemo;

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    Duration? duration,
    String? source,
    bool? isDemo,
    String? previewUrl,
    String? streamUrl,
    String? coverUrl,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      isDemo: isDemo ?? this.isDemo,
      previewUrl: previewUrl ?? this.previewUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  String get displayDuration {
    if (duration == null) return '--:--';
    final m = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Track> tracks;
  final String? coverColor;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    this.coverColor,
  });
}

class UsbDeviceInfo {
  final String name;
  final String path;
  final int trackCount;

  const UsbDeviceInfo({
    required this.name,
    required this.path,
    required this.trackCount,
  });
}
