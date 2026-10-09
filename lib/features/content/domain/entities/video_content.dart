import '../../../../core/models/video_quality.dart';

enum VideoType { movie, series, tvShow, documentary }

enum ContentStatus { draft, published, unpublished }

extension ContentStatusExtension on ContentStatus {
  String get label {
    switch (this) {
      case ContentStatus.draft:
        return '草稿';
      case ContentStatus.published:
        return '已发布';
      case ContentStatus.unpublished:
        return '已下线';
    }
  }
}

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
  final String? muxAssetId;
  final int playCount;

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
    this.muxAssetId,
    this.playCount = 0,
  });

  Episode copyWith({
    String? id,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? description,
    Duration? duration,
    String? thumbnailUrl,
    String? videoUrl,
    Map<VideoQuality, String>? videoUrls,
    String? muxAssetId,
    int? playCount,
  }) {
    return Episode(
      id: id ?? this.id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoUrls: videoUrls ?? this.videoUrls,
      muxAssetId: muxAssetId ?? this.muxAssetId,
      playCount: playCount ?? this.playCount,
    );
  }
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

  Season copyWith({
    int? seasonNumber,
    String? title,
    String? description,
    List<Episode>? episodes,
  }) {
    return Season(
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      episodes: episodes ?? this.episodes,
    );
  }
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
  final ContentStatus status;
  final int viewCount;
  final int playCount;
  final int totalWatchMinutes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? updatedAt;

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
    this.status = ContentStatus.published,
    this.viewCount = 0,
    this.playCount = 0,
    this.totalWatchMinutes = 0,
    this.createdBy,
    this.updatedBy,
    this.updatedAt,
  });

  bool get isSeries => type == VideoType.series || type == VideoType.tvShow;

  VideoContent copyWith({
    String? id,
    String? title,
    String? originalTitle,
    String? description,
    VideoType? type,
    int? releaseYear,
    Duration? duration,
    double? rating,
    String? maturityRating,
    List<String>? genres,
    List<String>? cast,
    List<String>? directors,
    String? posterUrl,
    String? backdropUrl,
    String? trailerUrl,
    String? mainVideoUrl,
    Map<VideoQuality, String>? mainVideoUrls,
    List<Season>? seasons,
    int? totalEpisodes,
    DateTime? addedAt,
    bool? isTrending,
    bool? isNewRelease,
    bool? isTopTen,
    int? topTenRank,
    ContentStatus? status,
    int? viewCount,
    int? playCount,
    int? totalWatchMinutes,
    String? createdBy,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return VideoContent(
      id: id ?? this.id,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      description: description ?? this.description,
      type: type ?? this.type,
      releaseYear: releaseYear ?? this.releaseYear,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      maturityRating: maturityRating ?? this.maturityRating,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      directors: directors ?? this.directors,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      mainVideoUrl: mainVideoUrl ?? this.mainVideoUrl,
      mainVideoUrls: mainVideoUrls ?? this.mainVideoUrls,
      seasons: seasons ?? this.seasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      addedAt: addedAt ?? this.addedAt,
      isTrending: isTrending ?? this.isTrending,
      isNewRelease: isNewRelease ?? this.isNewRelease,
      isTopTen: isTopTen ?? this.isTopTen,
      topTenRank: topTenRank ?? this.topTenRank,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      playCount: playCount ?? this.playCount,
      totalWatchMinutes: totalWatchMinutes ?? this.totalWatchMinutes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
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
