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
      MediaItem(
        title: "Friends - Best Moments S01",
        category: "🎬 Movies & Series",
        url: "https://www.youtube.com/watch?v=hDNNmeeJsCw",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Wednesday Netflix - Dance Scene",
        category: "🎬 Movies & Series",
        url: "https://www.youtube.com/watch?v=Di3SIm7y70A",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Pulp Fiction - Dance Scene HQ",
        category: "🎬 Movies & Series",
        url: "https://www.youtube.com/watch?v=WSLMN6g_Od4",
        hasSubtitles: false,
      ),
      MediaItem(
        title: "Metallica - Master of Puppets",
        category: "🎸 Rock Music",
        url: "https://www.youtube.com/watch?v=xnKhsTXoKCI",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Linkin Park - In The End",
        category: "🎸 Rock Music",
        url: "https://www.youtube.com/watch?v=eVTXPUF4Oz4",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Rammstein - Du Hast (No CC)",
        category: "🎸 Rock Music",
        url: "https://www.youtube.com/watch?v=W3q8Od5qJio",
        hasSubtitles: false,
      ),
      MediaItem(
        title: "TED Talk - The Power of Vulnerability",
        category: "🎓 TED Talks",
        url: "https://www.youtube.com/watch?v=iCvmsMzlF7o",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "BBC News - World Service",
        category: "📰 BBC News",
        url: "https://www.youtube.com/watch?v=live",
        hasSubtitles: true,
      ),
    ];
  }
}
