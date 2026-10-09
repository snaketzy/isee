enum UploadStage {
  local,
  uploadingToR2,
  r2Done,
  pullingToMux,
  transcoding,
  ready,
  failed,
  paused,
  cancelled,
}

extension UploadStageExtension on UploadStage {
  String get label {
    switch (this) {
      case UploadStage.local:
        return '等待上传';
      case UploadStage.uploadingToR2:
        return '上传至 R2';
      case UploadStage.r2Done:
        return 'R2 上传完成';
      case UploadStage.pullingToMux:
        return 'Mux 拉取中';
      case UploadStage.transcoding:
        return '转码中';
      case UploadStage.ready:
        return '已就绪';
      case UploadStage.failed:
        return '失败';
      case UploadStage.paused:
        return '已暂停';
      case UploadStage.cancelled:
        return '已取消';
    }
  }

  bool get isInProgress =>
      this == UploadStage.uploadingToR2 ||
      this == UploadStage.pullingToMux ||
      this == UploadStage.transcoding;

  bool get isCompleted => this == UploadStage.ready;
  bool get isFailed => this == UploadStage.failed || this == UploadStage.cancelled;
}

enum UploadPriority { low, normal, high, urgent }

extension UploadPriorityExtension on UploadPriority {
  String get label {
    switch (this) {
      case UploadPriority.low:
        return '低';
      case UploadPriority.normal:
        return '普通';
      case UploadPriority.high:
        return '高';
      case UploadPriority.urgent:
        return '紧急';
    }
  }
}

class UploadStageProgress {
  final UploadStage stage;
  final int percent;
  final double? speedMbps;
  final double? transferredMb;
  final double? totalMb;
  final int? etaSeconds;

  const UploadStageProgress({
    required this.stage,
    required this.percent,
    this.speedMbps,
    this.transferredMb,
    this.totalMb,
    this.etaSeconds,
  });
}

class MediaUploadTask {
  final String id;
  final String fileName;
  final String? displayTitle;
  final String? localFilePath;
  final String? r2Key;
  final String? r2PublicUrl;
  final String? muxAssetId;
  final String? muxPlaybackId;
  final String? videoContentId;
  final UploadStage stage;
  final UploadPriority priority;
  final List<UploadStageProgress> progressHistory;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? errorDetail;
  final int retryCount;
  final String? createdBy;
  final double fileSizeMb;

  const MediaUploadTask({
    required this.id,
    required this.fileName,
    this.displayTitle,
    this.localFilePath,
    this.r2Key,
    this.r2PublicUrl,
    this.muxAssetId,
    this.muxPlaybackId,
    this.videoContentId,
    required this.stage,
    this.priority = UploadPriority.normal,
    this.progressHistory = const [],
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.errorDetail,
    this.retryCount = 0,
    this.createdBy,
    this.fileSizeMb = 0,
  });

  UploadStageProgress get currentProgress {
    if (progressHistory.isNotEmpty) return progressHistory.last;
    return UploadStageProgress(stage: stage, percent: 0);
  }

  int get overallPercent {
    final weights = {
      UploadStage.local: 0,
      UploadStage.uploadingToR2: 1,
      UploadStage.r2Done: 25,
      UploadStage.pullingToMux: 30,
      UploadStage.transcoding: 55,
      UploadStage.ready: 100,
      UploadStage.failed: currentProgress.percent,
      UploadStage.paused: currentProgress.percent,
      UploadStage.cancelled: currentProgress.percent,
    };
    final baseWeight = weights[stage] ?? 0;
    if (stage == UploadStage.uploadingToR2 ||
        stage == UploadStage.pullingToMux ||
        stage == UploadStage.transcoding) {
      final stageStartWeight = stage == UploadStage.uploadingToR2
          ? 0
          : stage == UploadStage.pullingToMux
              ? 25
              : 30;
      final stageEndWeight = stage == UploadStage.uploadingToR2
          ? 25
          : stage == UploadStage.pullingToMux
              ? 30
              : 100;
      return (stageStartWeight +
              (stageEndWeight - stageStartWeight) *
                  (currentProgress.percent / 100))
          .round();
    }
    return baseWeight;
  }

  MediaUploadTask copyWith({
    String? id,
    String? fileName,
    String? displayTitle,
    String? localFilePath,
    String? r2Key,
    String? r2PublicUrl,
    String? muxAssetId,
    String? muxPlaybackId,
    String? videoContentId,
    UploadStage? stage,
    UploadPriority? priority,
    List<UploadStageProgress>? progressHistory,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorDetail,
    int? retryCount,
    String? createdBy,
    double? fileSizeMb,
  }) {
    return MediaUploadTask(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      displayTitle: displayTitle ?? this.displayTitle,
      localFilePath: localFilePath ?? this.localFilePath,
      r2Key: r2Key ?? this.r2Key,
      r2PublicUrl: r2PublicUrl ?? this.r2PublicUrl,
      muxAssetId: muxAssetId ?? this.muxAssetId,
      muxPlaybackId: muxPlaybackId ?? this.muxPlaybackId,
      videoContentId: videoContentId ?? this.videoContentId,
      stage: stage ?? this.stage,
      priority: priority ?? this.priority,
      progressHistory: progressHistory ?? this.progressHistory,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetail: errorDetail ?? this.errorDetail,
      retryCount: retryCount ?? this.retryCount,
      createdBy: createdBy ?? this.createdBy,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
    );
  }
}

class MuxAssetInfo {
  final String assetId;
  final String playbackId;
  final String? videoContentId;
  final String? title;
  final String status;
  final String maxResolution;
  final List<String> availableResolutions;
  final Duration duration;
  final double fileSizeMb;
  final DateTime createdAt;
  final DateTime? readyAt;
  final String? r2SourceUrl;
  final int playCount;
  final double bandwidthGb;

  const MuxAssetInfo({
    required this.assetId,
    required this.playbackId,
    this.videoContentId,
    this.title,
    required this.status,
    required this.maxResolution,
    this.availableResolutions = const [],
    required this.duration,
    required this.fileSizeMb,
    required this.createdAt,
    this.readyAt,
    this.r2SourceUrl,
    this.playCount = 0,
    this.bandwidthGb = 0,
  });

  String get playbackUrl =>
      'https://stream.mux.com/$playbackId.m3u8';
}

class R2FileItem {
  final String key;
  final String name;
  final String? parentKey;
  final bool isFolder;
  final double sizeMb;
  final DateTime lastModified;
  final String? etag;
  final String publicUrl;

  const R2FileItem({
    required this.key,
    required this.name,
    this.parentKey,
    this.isFolder = false,
    this.sizeMb = 0,
    required this.lastModified,
    this.etag,
    required this.publicUrl,
  });
}

class R2StorageStats {
  final double totalSizeGb;
  final int totalFiles;
  final double monthlyEgressGb;
  final int totalVideos;
  final double monthlyCostEstimate;

  const R2StorageStats({
    required this.totalSizeGb,
    required this.totalFiles,
    required this.monthlyEgressGb,
    required this.totalVideos,
    required this.monthlyCostEstimate,
  });
}
