class MediaItem {
  final String title;
  final String category;
  final String url;
  final bool hasSubtitles;
  final bool isCustom;

  const MediaItem({
    required this.title,
    required this.category,
    required this.url,
    this.hasSubtitles = true,
    this.isCustom = false,
  });
}
