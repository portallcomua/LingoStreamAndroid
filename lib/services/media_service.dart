import '../models/media_item.dart';

class MediaService {
  static List<MediaItem> getPredefinedMedia() {
    return const [
      MediaItem(
        title: 'Friends - Best Moments S01',
        category: '🎬 Серіали',
        url: 'https://www.youtube.com/watch?v=hDNNmeeJsCw',
      ),
      MediaItem(
        title: 'Wednesday - Dance Scene',
        category: '🎬 Серіали',
        url: 'https://www.youtube.com/watch?v=Di3SIm7y70A',
      ),
      MediaItem(
        title: 'TED - Power of Vulnerability',
        category: '🎓 TED Talks',
        url: 'https://www.youtube.com/watch?v=iCvmsMzlF7o',
      ),
      MediaItem(
        title: 'Metallica - Master of Puppets',
        category: '🎸 Rock',
        url: 'https://www.youtube.com/watch?v=xnKhsTXoKCI',
      ),
      MediaItem(
        title: 'Linkin Park - In The End',
        category: '🎸 Rock',
        url: 'https://www.youtube.com/watch?v=eVTXPUF4Oz4',
      ),
      MediaItem(
        title: 'Pulp Fiction - Dance Scene',
        category: '🎬 Кіно',
        url: 'https://www.youtube.com/watch?v=WSLMN6g_Od4',
        hasSubtitles: false,
      ),
    ];
  }
}
