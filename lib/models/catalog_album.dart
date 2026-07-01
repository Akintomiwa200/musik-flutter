class CatalogAlbum {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final int? trackCount;

  const CatalogAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    this.trackCount,
  });
}
