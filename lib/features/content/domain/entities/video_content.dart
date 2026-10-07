import '../../../../core/models/video_quality.dart';

enum VideoType { movie, series, tvShow, documentary }

class Episode {
  final String id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String description;
  final Duration duration;
  final String thumbnailUrl;
  final String? videoUrl;
  final Map<VideoQuality, String>? videoUrls;

  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.duration,
    required this.thumbnailUrl,
    this.videoUrl,
    this.videoUrls,
  });
}

class Season {
  final int seasonNumber;
  final String title;
  final String description;
  final List<Episode> episodes;

  const Season({
    required this.seasonNumber,
    required this.title,
    required this.description,
    required this.episodes,
  });
}

class VideoContent {
  final String id;
  final String title;
  final String originalTitle;
  final String description;
  final VideoType type;
  final int releaseYear;
  final Duration? duration;
  final double rating;
  final String maturityRating;
  final List<String> genres;
  final List<String> cast;
  final List<String> directors;
  final String posterUrl;
  final String backdropUrl;
  final String? trailerUrl;
  final String? mainVideoUrl;
  final Map<VideoQuality, String>? mainVideoUrls;
  final List<Season>? seasons;
  final int? totalEpisodes;
  final DateTime addedAt;
  final bool isTrending;
  final bool isNewRelease;
  final bool isTopTen;
  final int? topTenRank;

  const VideoContent({
    required this.id,
    required this.title,
    this.originalTitle = '',
    required this.description,
    required this.type,
    required this.releaseYear,
    this.duration,
    this.rating = 0.0,
    this.maturityRating = 'TV-MA',
    this.genres = const [],
    this.cast = const [],
    this.directors = const [],
    required this.posterUrl,
    required this.backdropUrl,
    this.trailerUrl,
    this.mainVideoUrl,
    this.mainVideoUrls,
    this.seasons,
    this.totalEpisodes,
    required this.addedAt,
    this.isTrending = false,
    this.isNewRelease = false,
    this.isTopTen = false,
    this.topTenRank,
  });

  bool get isSeries => type == VideoType.series || type == VideoType.tvShow;
}

class VideoCategory {
  final String id;
  final String name;
  final List<VideoContent> videos;

  const VideoCategory({
    required this.id,
    required this.name,
    required this.videos,
  });
}
