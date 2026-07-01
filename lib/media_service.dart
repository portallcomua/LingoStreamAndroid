class MediaItem {
  final String title;
  final String category;
  final bool hasSubtitles;

  MediaItem({
    required this.title,
    required this.category,
    this.hasSubtitles = true,
  });
}

class MediaService {
  static List<MediaItem> getPredefinedMedia() {
    return [
      MediaItem(title: "Metallica - Master of Puppets", category: "🎸 Rock Music", hasSubtitles: true),
      MediaItem(title: "Linkin Park - In The End", category: "🎸 Rock Music", hasSubtitles: true),
      MediaItem(title: "Rammstein - Du Hast", category: "🎸 Rock Music", hasSubtitles: false),
      MediaItem(title: "Friends - Best Moments S01", category: "🎬 Movies & Series", hasSubtitles: true),
      MediaItem(title: "Wednesday Netflix - Dance Scene", category: "🎬 Movies & Series", hasSubtitles: true),
      MediaItem(title: "Pulp Fiction - Dance Scene HQ", category: "🎬 Movies & Series", hasSubtitles: false),
    ];
  }
}
