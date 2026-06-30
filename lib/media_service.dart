class MediaItem {
  final String title;
  final String category;
  final String url;
  final bool hasSubtitles; // Маркер наявності субтитрів для безпеки перекладу

  MediaItem({
    required this.title,
    required this.category,
    required this.url,
    this.hasSubtitles = true,
  });
}

class MediaService {
  static List<MediaItem> getPredefinedMedia() {
    return [
      MediaItem(title: "Metallica - Master of Puppets (Live Official)", category: "🎸 Rock Music", url: "https://youtube.com", hasSubtitles: true),
      MediaItem(title: "Linkin Park - In The End (HD Video)", category: "🎸 Rock Music", url: "https://youtube.com", hasSubtitles: true),
      MediaItem(title: "Rammstein - Du Hast (Lyrics Track)", category: "🎸 Rock Music", url: "https://youtube.com", hasSubtitles: false), // Немає CC
      MediaItem(title: "Friends - Best Funny Moments Season 1", category: "🎬 Movies & Series", url: "https://youtube.com", hasSubtitles: true),
      MediaItem(title: "Wednesday Netflix - Dance Scene (Full)", category: "🎬 Movies & Series", url: "https://youtube.com", hasSubtitles: true),
      MediaItem(title: "Pulp Fiction - Dance Scene HQ", category: "🎬 Movies & Series", url: "https://youtube.com", hasSubtitles: false), // Немає CC
    ];
  }
}
