enum VideoQuality { q360p, q480p, q720p, q1080p, q4k }

extension VideoQualityExtension on VideoQuality {
  String get label {
    switch (this) {
      case VideoQuality.q360p:
        return '360p';
      case VideoQuality.q480p:
        return '480p';
      case VideoQuality.q720p:
        return '720p HD';
      case VideoQuality.q1080p:
        return '1080p Full HD';
      case VideoQuality.q4k:
        return '4K Ultra HD';
    }
  }

  int get bitrate {
    switch (this) {
      case VideoQuality.q360p:
        return 500;
      case VideoQuality.q480p:
        return 1000;
      case VideoQuality.q720p:
        return 2500;
      case VideoQuality.q1080p:
        return 4500;
      case VideoQuality.q4k:
        return 12000;
    }
  }
}

enum PlaybackSpeed {
  x0_5,
  x0_75,
  x1_0,
  x1_25,
  x1_5,
  x1_75,
  x2_0,
}

extension PlaybackSpeedExtension on PlaybackSpeed {
  double get value {
    switch (this) {
      case PlaybackSpeed.x0_5:
        return 0.5;
      case PlaybackSpeed.x0_75:
        return 0.75;
      case PlaybackSpeed.x1_0:
        return 1.0;
      case PlaybackSpeed.x1_25:
        return 1.25;
      case PlaybackSpeed.x1_5:
        return 1.5;
      case PlaybackSpeed.x1_75:
        return 1.75;
      case PlaybackSpeed.x2_0:
        return 2.0;
    }
  }

  String get label {
    switch (this) {
      case PlaybackSpeed.x1_0:
        return '正常速度';
      default:
        return '${value}x';
    }
  }
}
