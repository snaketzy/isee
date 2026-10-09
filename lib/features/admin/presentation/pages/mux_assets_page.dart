import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_upload_task.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/data_table.dart';

class MuxAssetsPage extends ConsumerStatefulWidget {
  final String? id;
  const MuxAssetsPage({super.key, this.id});

  @override
  ConsumerState<MuxAssetsPage> createState() => _MuxAssetsPageState();
}

class _MuxAssetsPageState extends ConsumerState<MuxAssetsPage> {
  String _statusFilter = 'all';
  String _resolutionFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const List<String> _statusOptions = [
    'all',
    'ready',
    'preparing',
    'errored',
  ];

  static const List<String> _resolutionOptions = [
    'all',
    '360p',
    '480p',
    '720p',
    '1080p',
    '1440p',
    '2160p',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MuxAssetInfo> get _filteredAssets {
    final all = AdminMockRepository.instance.getAllMuxAssets();
    return all.where((a) {
      if (_statusFilter != 'all' && a.status != _statusFilter) return false;
      if (_resolutionFilter != 'all' && a.maxResolution != _resolutionFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!a.assetId.toLowerCase().contains(q) &&
            !(a.title ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get _total => AdminMockRepository.instance.getAllMuxAssets().length;
  int get _preparing => AdminMockRepository.instance
      .getAllMuxAssets()
      .where((a) => a.status == 'preparing')
      .length;
  double get _weekBandwidth => AdminMockRepository.instance
      .getAllMuxAssets()
      .fold<double>(0, (sum, a) => sum + a.bandwidthGb);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'zh_CN');
    final bwFmt = NumberFormat('#,##0.0', 'zh_CN');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatGrid(fmt, bwFmt),
          const SizedBox(height: 20),
          _buildFilterBar(),
          const SizedBox(height: 16),
          _buildAssetTable(fmt, bwFmt),
          const SizedBox(height: 24),
        ],
      ),
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
                'Mux 资产监控',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '管理 Mux 转码资产、播放链接与带宽消耗',
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

  Widget _buildStatGrid(NumberFormat fmt, NumberFormat bwFmt) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1100
            ? 3
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
                title: '资产总数',
                value: fmt.format(_total),
                subtitle: '全部 Mux 转码资产',
                icon: Icons.video_library_rounded,
                accentColor: const Color(0xFF60A5FA),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '转码中',
                value: fmt.format(_preparing),
                subtitle: '正在处理的资产',
                icon: Icons.smart_toy_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '本周带宽消耗',
                value: '${bwFmt.format(_weekBandwidth)} GB',
                subtitle: '累计播放产生的流量',
                icon: Icons.network_check_rounded,
                accentColor: const Color(0xFFA78BFA),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list_rounded,
                  color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _statusFilter,
                items: _statusOptions,
                labels: const {
                  'all': '全部状态',
                  'ready': '已就绪',
                  'preparing': '转码中',
                  'errored': '错误',
                },
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
              const SizedBox(width: 10),
              _buildDropdown(
                value: _resolutionFilter,
                items: _resolutionOptions,
                labels: const {
                  'all': '全部分辨率',
                  '360p': '360p 及以上',
                  '480p': '480p 及以上',
                  '720p': '720p 及以上',
                  '1080p': '1080p 及以上',
                  '1440p': '1440p 及以上',
                  '2160p': '2160p (4K)',
                },
                onChanged: (v) => setState(() => _resolutionFilter = v),
              ),
            ],
          ),
          SizedBox(
            width: 320,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索 Asset ID 或视频标题...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 16, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceLight,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryRed),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Map<String, String> labels,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: (v) => onChanged(v ?? items.first),
        underline: const SizedBox.shrink(),
        dropdownColor: AppTheme.surfaceDark,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(labels[e] ?? e),
                ))
            .toList(),
        icon: const Icon(Icons.expand_more_rounded,
            size: 18, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildAssetTable(NumberFormat fmt, NumberFormat bwFmt) {
    final list = _filteredAssets;
    return AdminDataTable<MuxAssetInfo>(
      headerTitle: '资产列表（${list.length} 项）',
      items: list,
      selectable: false,
      noResultText: '没有匹配的资产',
      columns: const [
        DataColumnSpec(label: 'Asset ID', width: 200),
        DataColumnSpec(label: '关联视频标题'),
        DataColumnSpec(label: '状态'),
        DataColumnSpec(label: '最高分辨率', numeric: true),
        DataColumnSpec(label: '时长', numeric: true),
        DataColumnSpec(label: '大小', numeric: true),
        DataColumnSpec(label: '播放次数', numeric: true),
        DataColumnSpec(label: '带宽 (GB)', numeric: true),
        DataColumnSpec(label: '创建时间', width: 150),
        DataColumnSpec(label: '操作', width: 180),
      ],
      rowBuilder: (ctx, asset, _) {
        return DataRow(cells: [
          DataCell(
            SelectableText(
              asset.assetId,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          DataCell(
            asset.title != null
                ? InkWell(
                    onTap: asset.videoContentId != null
                        ? () => context.go('/admin/content/${asset.videoContentId}')
                        : null,
                    child: Text(
                      asset.title!,
                      style: TextStyle(
                        color: asset.videoContentId != null
                            ? AppTheme.primaryRed
                            : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: asset.videoContentId != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  )
                : const Text(
                    '未关联',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
          ),
          DataCell(_buildStatusChip(asset.status)),
          DataTextCell(asset.maxResolution,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              numeric: true),
          DataTextCell(_formatDuration(asset.duration), numeric: true),
          DataTextCell(_formatSize(asset.fileSizeMb), numeric: true),
          DataTextCell(fmt.format(asset.playCount), numeric: true),
          DataTextCell(bwFmt.format(asset.bandwidthGb), numeric: true),
          DataTextCell(
            DateFormat('MM-dd HH:mm').format(asset.createdAt),
            color: AppTheme.textSecondary,
            numeric: true,
          ),
          DataCell(
            Row(
              children: [
                _TableAction(
                  icon: Icons.copy_rounded,
                  tooltip: '复制 Playback URL',
                  onTap: () => _copyPlaybackUrl(asset),
                  color: const Color(0xFF60A5FA),
                ),
                const SizedBox(width: 4),
                _TableAction(
                  icon: Icons.open_in_new_rounded,
                  tooltip: '预览播放',
                  onTap: () => _openPreview(asset),
                  color: const Color(0xFF4ADE80),
                ),
                const SizedBox(width: 4),
                _TableAction(
                  icon: Icons.link_rounded,
                  tooltip: '关联内容',
                  onTap: () => _linkToContent(asset),
                  color: const Color(0xFFA78BFA),
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildStatusChip(String status) {
    switch (status) {
      case 'ready':
        return StatusChip.byVariant('已就绪', StatusVariant.success);
      case 'preparing':
        return StatusChip.byVariant('转码中', StatusVariant.warning);
      case 'errored':
        return StatusChip.byVariant('错误', StatusVariant.error);
      default:
        return StatusChip.byVariant(status, StatusVariant.neutral);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds == 0) return '-';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatSize(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  void _copyPlaybackUrl(MuxAssetInfo asset) async {
    await Clipboard.setData(ClipboardData(text: asset.playbackUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Playback URL 已复制到剪贴板'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openPreview(MuxAssetInfo asset) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.title ?? '未命名资产',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Playback ID: ${asset.playbackId}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 450,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://picsum.photos/seed/mux_${asset.assetId.substring(0, min(8, asset.assetId.length))}/800/450',
                    ),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _linkToContent(MuxAssetInfo asset) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('为 ${asset.title ?? asset.assetId} 选择要关联的内容'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TableAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _TableAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
