import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_upload_task.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/data_table.dart';

class R2StoragePage extends ConsumerStatefulWidget {
  final String? id;
  const R2StoragePage({super.key, this.id});

  @override
  ConsumerState<R2StoragePage> createState() => _R2StoragePageState();
}

class _R2StoragePageState extends ConsumerState<R2StoragePage> {
  String _currentPath = '';
  R2FileItem? _selectedFile;
  late R2StorageStats _stats;
  late List<R2FileItem> _files;

  @override
  void initState() {
    super.initState();
    _stats = AdminMockRepository.instance.getR2Stats();
    _files = AdminMockRepository.instance.browseR2Folder(_currentPath);
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _files = AdminMockRepository.instance.browseR2Folder(_currentPath);
      _selectedFile = null;
    });
  }

  void _goParent() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/')..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) {
      _navigateTo('');
    } else {
      parts.removeLast();
      _navigateTo(parts.isEmpty ? '' : '${parts.join('/')}/');
    }
  }

  List<String> get _breadcrumbParts {
    final parts = _currentPath.split('/')..removeWhere((p) => p.isEmpty);
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'zh_CN');
    final bwFmt = NumberFormat('#,##0.0', 'zh_CN');
    final costFmt = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '\$',
      decimalDigits: 2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildHeader(),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildStatGrid(fmt, bwFmt, costFmt),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildMainContent(fmt),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: const [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'R2 存储浏览',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '浏览 Cloudflare R2 对象存储，管理视频与资源文件',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(
    NumberFormat fmt,
    NumberFormat bwFmt,
    NumberFormat costFmt,
  ) {
    final monthlyCost = _stats.monthlyEgressGb * 0.01;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1400
            ? 5
            : constraints.maxWidth > 1100
                ? 4
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '总容量',
                value: bwFmt.format(_stats.totalSizeGb) + ' GB',
                subtitle: '已占用存储',
                icon: Icons.storage_rounded,
                accentColor: const Color(0xFF60A5FA),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '文件总数',
                value: fmt.format(_stats.totalFiles),
                subtitle: '全部对象数',
                icon: Icons.folder_copy_rounded,
                accentColor: const Color(0xFFA78BFA),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '视频文件',
                value: fmt.format(_stats.totalVideos),
                subtitle: '媒体资源文件',
                icon: Icons.movie_creation_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '月出向流量',
                value: bwFmt.format(_stats.monthlyEgressGb) + ' GB',
                subtitle: '本月公网访问',
                icon: Icons.upload_file_rounded,
                accentColor: const Color(0xFF4ADE80),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '估算费用',
                value: costFmt.format(monthlyCost),
                subtitle: 'R2 免费额度内',
                icon: Icons.payments_rounded,
                accentColor: AppTheme.primaryRed,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(NumberFormat fmt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildBreadcrumb(),
              const SizedBox(height: 12),
              Expanded(child: _buildFileTable(fmt)),
            ],
          ),
        ),
        if (_selectedFile != null) ...[
          const SizedBox(width: 20),
          SizedBox(
            width: 360,
            child: _buildPreviewPanel(fmt),
          ),
        ],
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _currentPath.isNotEmpty ? () => _navigateTo('') : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _currentPath.isEmpty
                    ? AppTheme.primaryRed.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.home_rounded,
                size: 18,
                color: _currentPath.isEmpty
                    ? AppTheme.primaryRed
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          if (_currentPath.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppTheme.textMuted),
            ),
            ..._breadcrumbParts.asMap().entries.map((e) {
              final idx = e.key;
              final part = e.value;
              final isLast = idx == _breadcrumbParts.length - 1;
              final builtPath =
                  _breadcrumbParts.sublist(0, idx + 1).join('/') + '/';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isLast ? null : () => _navigateTo(builtPath),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLast
                            ? AppTheme.surfaceLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 14,
                            color: isLast
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            part,
                            style: TextStyle(
                              color: isLast
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight:
                                  isLast ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppTheme.textMuted),
                    ),
                ],
              );
            }).toList(),
            const Spacer(),
            TextButton.icon(
              onPressed: _goParent,
              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
              label: const Text('上级', style: TextStyle(fontSize: 12)),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFileTable(NumberFormat fmt) {
    return AdminDataTable<R2FileItem>(
      headerTitle: _currentPath.isEmpty ? '根目录' : _currentPath,
      items: _files,
      selectable: false,
      columns: const [
        DataColumnSpec(label: '名称'),
        DataColumnSpec(label: '大小', numeric: true, width: 110),
        DataColumnSpec(label: 'Last Modified', width: 160),
        DataColumnSpec(label: 'ETag', width: 220),
        DataColumnSpec(label: '公网 URL', width: 140),
      ],
      rowBuilder: (ctx, file, _) {
        final isSelected = _selectedFile?.key == file.key;
        return DataRow(
          color: isSelected
              ? WidgetStateProperty.all(AppTheme.primaryRed.withOpacity(0.08))
              : null,
          onSelectChanged: (_) {
            if (file.isFolder) {
              _navigateTo(file.key);
            } else {
              setState(() => _selectedFile = file);
            }
          },
          cells: [
            DataCell(
              Row(
                children: [
                  Icon(
                    file.isFolder
                        ? Icons.folder_rounded
                        : _fileIcon(file.name),
                    size: 18,
                    color: file.isFolder
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: file.isFolder
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DataTextCell(
              file.isFolder ? '-' : _formatSize(file.sizeMb),
              numeric: true,
              color: AppTheme.textSecondary,
            ),
            DataTextCell(
              DateFormat('yyyy-MM-dd HH:mm').format(file.lastModified),
              color: AppTheme.textSecondary,
            ),
            DataCell(
              file.etag != null
                  ? SelectableText(
                      file.etag!,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    )
                  : const Text(
                      '-',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
            ),
            DataCell(
              Tooltip(
                message: file.publicUrl,
                child: InkWell(
                  onTap: () => _copyUrl(file),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy_rounded,
                            size: 14, color: Color(0xFF60A5FA)),
                        SizedBox(width: 4),
                        Text(
                          '复制',
                          style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewPanel(NumberFormat fmt) {
    final file = _selectedFile!;
    final isImage = _isImage(file.name);
    final isVideo = _isVideo(file.name);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.preview_rounded,
                    size: 18,
                    color: isImage
                        ? const Color(0xFFA78BFA)
                        : isVideo
                            ? const Color(0xFFF59E0B)
                            : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '预览面板',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedFile = null),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                image: isImage || isVideo
                    ? DecorationImage(
                        image: NetworkImage(
                          isImage
                              ? file.publicUrl
                              : 'https://picsum.photos/seed/r2_v_${file.key.hashCode}/400/220',
                        ),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: isVideo && !isImage
                  ? Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    )
                  : !isImage
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _fileIcon(file.name),
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '此文件类型不支持预览',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('大小', _formatSize(file.sizeMb)),
                  _buildInfoRow(
                    'Last Modified',
                    DateFormat('yyyy-MM-dd HH:mm').format(file.lastModified),
                  ),
                  if (file.etag != null)
                    _buildInfoRow('ETag', file.etag!, mono: true),
                  _buildInfoRow('Key', file.key, mono: true),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 12),
                  const Text(
                    '公网 URL',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    file.publicUrl,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyUrl(file),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('复制 URL',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadFile(file),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label:
                              const Text('下载', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontFamily: mono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm')) {
      return Icons.movie_rounded;
    }
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return Icons.image_rounded;
    }
    if (lower.endsWith('.md') || lower.endsWith('.txt')) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  bool _isImage(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  bool _isVideo(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm');
  }

  String _formatSize(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    if (mb * 1024 >= 1) return '${(mb * 1024).toStringAsFixed(0)} KB';
    return '${(mb * 1024 * 1024).toStringAsFixed(0)} B';
  }

  void _copyUrl(R2FileItem file) async {
    await Clipboard.setData(ClipboardData(text: file.publicUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL 已复制：${file.name}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _downloadFile(R2FileItem file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始下载：${file.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
