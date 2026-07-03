class MediaItem {
  final String title;
  final String category;
  final String url;
  final bool hasSubtitles;
  final bool isCustom;

  MediaItem({
    required this.title,
    required this.category,
    required this.url,
    this.hasSubtitles = true,
    this.isCustom = false,
  });
}

class MediaService {
  static List<MediaItem> getPredefinedMedia() {
    return [
      MediaItem(title: "Friends - Best Moments S01", category: "🎬 Серіали", url: "https://www.youtube.com/watch?v=hDNNmeeJsCw", hasSubtitles: true),
      MediaItem(title: "Wednesday - Dance Scene", category: "🎬 Серіали", url: "https://www.youtube.com/watch?v=Di3SIm7y70A", hasSubtitles: true),
      MediaItem(title: "TED - Power of Vulnerability", category: "🎓 TED Talks", url: "https://www.youtube.com/watch?v=iCvmsMzlF7o", hasSubtitles: true),
      MediaItem(title: "Metallica - Master of Puppets", category: "🎸 Rock", url: "https://www.youtube.com/watch?v=xnKhsTXoKCI", hasSubtitles: true),
      MediaItem(title: "Linkin Park - In The End", category: "🎸 Rock", url: "https://www.youtube.com/watch?v=eVTXPUF4Oz4", hasSubtitles: true),
      MediaItem(title: "Pulp Fiction - Dance Scene", category: "🎬 Кіно", url: "https://www.youtube.com/watch?v=WSLMN6g_Od4", hasSubtitles: false),
    ];
  }
}
