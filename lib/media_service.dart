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
      // ===== 🎸 ROCK =====
      MediaItem(
        title: "Metallica - Master of Puppets (Lyrics)",
        category: "🎸 Rock",
        url: "https://www.youtube.com/results?search_query=Metallica+Master+of+Puppets+lyrics",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Linkin Park - In The End (Lyrics)",
        category: "🎸 Rock",
        url: "https://www.youtube.com/results?search_query=Linkin+Park+In+The+End+lyrics",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Bon Jovi - It's My Life (Lyrics)",
        category: "🎸 Rock",
        url: "https://www.youtube.com/results?search_query=Bon+Jovi+Its+My+Life+lyrics",
        hasSubtitles: true,
      ),

      // ===== 🎬 MOVIES =====
      MediaItem(
        title: "Friends - English Subtitles",
        category: "🎬 Movies",
        url: "https://www.youtube.com/results?search_query=Friends+english+subtitles",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Harry Potter - English Subtitles",
        category: "🎬 Movies",
        url: "https://www.youtube.com/results?search_query=Harry+Potter+english+subtitles",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Sherlock BBC - English Subtitles",
        category: "🎬 Movies",
        url: "https://www.youtube.com/results?search_query=Sherlock+BBC+english+subtitles",
        hasSubtitles: true,
      ),

      // ===== 🧒 CARTOONS =====
      MediaItem(
        title: "Peppa Pig English",
        category: "🧒 Cartoons",
        url: "https://www.youtube.com/results?search_query=Peppa+Pig+english+subtitles",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "Bluey English",
        category: "🧒 Cartoons",
        url: "https://www.youtube.com/results?search_query=Bluey+english+subtitles",
        hasSubtitles: true,
      ),

      // ===== 🎤 TED =====
      MediaItem(
        title: "TED Talks - English Subtitles",
        category: "🎤 TED",
        url: "https://www.youtube.com/results?search_query=TED+Talks+english+subtitles",
        hasSubtitles: true,
      ),

      // ===== 📚 LEARNING ENGLISH =====
      MediaItem(
        title: "BBC Learning English",
        category: "📚 Навчання",
        url: "https://www.youtube.com/results?search_query=BBC+Learning+English",
        hasSubtitles: true,
      ),
      MediaItem(
        title: "English with Lucy",
        category: "📚 Навчання",
        url: "https://www.youtube.com/results?search_query=English+with+Lucy",
        hasSubtitles: true,
      ),

      // ===== 🇺🇦 UKRAINIAN =====
      MediaItem(
        title: "Українські пісні з субтитрами",
        category: "🇺🇦 Українські",
        url: "https://www.youtube.com/results?search_query=українські+пісні+з+субтитрами",
        hasSubtitles: true,
      ),
    ];
  }

  static bool hasLogo() => true;
}