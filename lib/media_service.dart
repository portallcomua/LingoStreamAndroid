class MediaItem {
  final String title;
  final String category;
  final String videoId; // Тільки ID відео (наприклад xnKhsTXoKCI)
  final bool hasSubtitles;

  MediaItem({
    required this.title,
    required this.category,
    required this.videoId,
    this.hasSubtitles = true,
  });

  // Функція, яка сама збирає повне посилання всередині додатка
  String get fullUrl => 'https://youtube.com';
}

class MediaService {
  static List<MediaItem> getPredefinedMedia() {
    return [
      MediaItem(title: "Metallica - Master of Puppets", category: "🎸 Rock Music", videoId: "xnKhsTXoKCI", hasSubtitles: true),
      MediaItem(title: "Linkin Park - In The End", category: "🎸 Rock Music", videoId: "eVTXPUF4Oz4", hasSubtitles: true),
      MediaItem(title: "Rammstein - Du Hast", category: "🎸 Rock Music", videoId: "W3q8Od5qJio", hasSubtitles: false),
      MediaItem(title: "Friends - Best Moments S01", category: "🎬 Movies & Series", videoId: "hDNNmeeJsCw", hasSubtitles: true),
      MediaItem(title: "Wednesday Netflix - Dance Scene", category: "🎬 Movies & Series", videoId: "Di3SIm7y70A", hasSubtitles: true),
      MediaItem(title: "Pulp Fiction - Dance Scene HQ", category: "🎬 Movies & Series", videoId: "WSLMN6g_Od4", hasSubtitles: false),
    ];
  }
}
