import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_upload_task.dart';

class UploadProgressTile extends StatelessWidget {
  final MediaUploadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onViewLogs;
  final VoidCallback? onTap;

  const UploadProgressTile({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onRetry,
    this.onCancel,
    this.onViewLogs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stage = task.stage;
    final cur = task.currentProgress;
    final overall = task.overallPercent;
    final Color color;
    final IconData icon;
    switch (stage) {
      case UploadStage.ready:
        color = const Color(0xFF4ADE80);
        icon = Icons.check_circle_rounded;
        break;
      case UploadStage.failed:
        color = const Color(0xFFF87171);
        icon = Icons.error_rounded;
        break;
      case UploadStage.cancelled:
        color = AppTheme.textMuted;
        icon = Icons.cancel_rounded;
        break;
      case UploadStage.paused:
        color = const Color(0xFFFBBF24);
        icon = Icons.pause_circle_rounded;
        break;
      case UploadStage.transcoding:
        color = const Color(0xFFA78BFA);
        icon = Icons.smart_toy_rounded;
        break;
      case UploadStage.uploadingToR2:
        color = const Color(0xFF60A5FA);
        icon = Icons.cloud_upload_rounded;
        break;
      case UploadStage.pullingToMux:
        color = const Color(0xFFF59E0B);
        icon = Icons.cloud_download_rounded;
        break;
      case UploadStage.r2Done:
        color = const Color(0xFF22D3EE);
        icon = Icons.cloud_done_rounded;
        break;
      case UploadStage.local:
        color = AppTheme.textSecondary;
        icon = Icons.schedule_rounded;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.displayTitle ?? task.fileName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stage.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.fileName} · ${_formatSize(task.fileSizeMb)}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: overall / 100,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$overall% 完成',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (cur.speedMbps != null && stage.isInProgress)
                          Text(
                            '${cur.speedMbps!.toStringAsFixed(1)} MB/s',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (cur.etaSeconds != null && cur.etaSeconds! > 0)
                          Text(
                            '剩余 ${_formatDuration(cur.etaSeconds!)}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        const Spacer(),
                        _buildActions(context, stage),
                      ],
                    ),
                    if (task.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF87171).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFF87171).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFF87171),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, UploadStage stage) {
    final iconColor = AppTheme.textSecondary;
    return Row(
      children: [
        if (stage.isInProgress)
          _IconAction(
            icon: Icons.pause_rounded,
            color: iconColor,
            tooltip: '暂停',
            onTap: onPause,
          ),
        if (stage == UploadStage.paused)
          _IconAction(
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFF4ADE80),
            tooltip: '继续',
            onTap: onResume,
          ),
        if (stage == UploadStage.failed)
          _IconAction(
            icon: Icons.refresh_rounded,
            color: const Color(0xFF60A5FA),
            tooltip: '重试',
            onTap: onRetry,
          ),
        if (!stage.isCompleted && !stage.isFailed)
          _IconAction(
            icon: Icons.cancel_rounded,
            color: const Color(0xFFF87171),
            tooltip: '取消',
            onTap: onCancel,
          ),
        _IconAction(
          icon: Icons.article_outlined,
          color: iconColor,
          tooltip: '查看日志',
          onTap: onViewLogs,
        ),
      ],
    );
  }

  String _formatSize(double mb) {
    if (mb >= 10240) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }

  String _formatDuration(int s) {
    if (s < 60) return '${s}s';
    if (s < 3600) return '${s ~/ 60}m ${s % 60}s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
