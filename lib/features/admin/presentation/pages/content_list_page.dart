import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../content/domain/entities/video_content.dart';
import '../../data/providers/admin_content_provider.dart';
import '../widgets/data_table.dart';

enum ViewMode { table, grid }

class ContentListPage extends ConsumerStatefulWidget {
  const ContentListPage({super.key});

  @override
  ConsumerState<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends ConsumerState<ContentListPage> {
  ViewMode _viewMode = ViewMode.table;
  String _searchQuery = '';
  VideoType? _filterType;
  ContentStatus? _filterStatus;
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VideoContent> get _filteredContent {
    final List<VideoContent> list = ref.watch(adminContentListProvider);
    return list.where((VideoContent v) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = v.title.toLowerCase().contains(q);
        final matchOriginal = v.originalTitle.toLowerCase().contains(q);
        final matchGenre = v.genres.any((g) => g.toLowerCase().contains(q));
        if (!matchTitle && !matchOriginal && !matchGenre) return false;
      }
      if (_filterType != null && v.type != _filterType) return false;
      if (_filterStatus != null && v.status != _filterStatus) return false;
      return true;
    }).toList();
  }

  void _toggleSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _handleBatchAction(ContentStatus status) {
    if (_selectedIds.isEmpty) return;
    final notifier = ref.read(adminContentListProvider.notifier);
    notifier.updateStatus(_selectedIds.toList(), status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将 ${_selectedIds.length} 项内容标记为「${status.label}」'),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
    _clearSelection();
  }

  void _handleBatchDelete() {
    if (_selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('确认删除', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '确定要删除选中的 ${_selectedIds.length} 项内容吗？此操作不可撤销。',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final notifier = ref.read(adminContentListProvider.notifier);
              for (final id in _selectedIds) {
                notifier.delete(id);
              }
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除 ${_selectedIds.length} 项内容'),
                  backgroundColor: AppTheme.surfaceLight,
                ),
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContent;
    final fmt = NumberFormat('#,##0', 'zh_CN');
    final dateFmt = DateFormat('yyyy-MM-dd');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 16),
          if (_selectedIds.isNotEmpty) _buildBatchActionBar(),
          if (_selectedIds.isNotEmpty) const SizedBox(height: 16),
          _viewMode == ViewMode.table
              ? _buildTableView(filtered, fmt, dateFmt)
              : _buildGridView(filtered, fmt, dateFmt),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = ref.watch(adminContentListProvider).length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '内容管理',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '共 $total 条内容 · 管理平台全部视频、剧集和节目',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        _buildViewToggle(),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => context.go('/admin/content/new'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('新建内容'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.table_chart_rounded,
            label: '表格',
            selected: _viewMode == ViewMode.table,
            onTap: () => setState(() => _viewMode = ViewMode.table),
          ),
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            label: '网格',
            selected: _viewMode == ViewMode.grid,
            onTap: () => setState(() => _viewMode = ViewMode.grid),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索标题、原名、分类...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          _buildDropdown<VideoType?>(
            value: _filterType,
            hint: '视频类型',
            items: const [
              DropdownMenuItem(value: null, child: Text('全部类型')),
              DropdownMenuItem(value: VideoType.movie, child: Text('电影')),
              DropdownMenuItem(value: VideoType.series, child: Text('剧集')),
              DropdownMenuItem(value: VideoType.tvShow, child: Text('节目')),
              DropdownMenuItem(value: VideoType.documentary, child: Text('纪录片')),
            ],
            onChanged: (v) => setState(() => _filterType = v),
          ),
          _buildDropdown<ContentStatus?>(
            value: _filterStatus,
            hint: '发布状态',
            items: const [
              DropdownMenuItem(value: null, child: Text('全部状态')),
              DropdownMenuItem(value: ContentStatus.draft, child: Text('草稿')),
              DropdownMenuItem(value: ContentStatus.published, child: Text('已发布')),
              DropdownMenuItem(value: ContentStatus.unpublished, child: Text('已下线')),
            ],
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _filterType = null;
                _filterStatus = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('重置筛选'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildBatchActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist_rounded, color: AppTheme.primaryRed, size: 20),
          const SizedBox(width: 8),
          Text(
            '已选择 ${_selectedIds.length} 项',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => _handleBatchAction(ContentStatus.published),
            child: const Text('批量发布'),
          ),
          TextButton(
            onPressed: () => _handleBatchAction(ContentStatus.unpublished),
            child: const Text('批量下线'),
          ),
          TextButton(
            onPressed: () => _handleBatchAction(ContentStatus.draft),
            child: const Text('转为草稿'),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearSelection,
            child: const Text('取消选择'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _handleBatchDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('删除'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryRed,
              side: BorderSide(color: AppTheme.primaryRed.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<VideoContent> list, NumberFormat fmt, DateFormat dateFmt) {
    return AdminDataTable<VideoContent>(
      headerTitle: '内容列表',
      headerAction: Text('共 ${list.length} 条', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      items: list,
      selectable: true,
      onSelectionChanged: (selected) {
        setState(() {
          _selectedIds.clear();
          _selectedIds.addAll(selected.map((e) => e.id));
        });
      },
      columns: const [
        DataColumnSpec(label: '封面', width: 80),
        DataColumnSpec(label: '标题'),
        DataColumnSpec(label: '类型', width: 90),
        DataColumnSpec(label: '状态', width: 100),
        DataColumnSpec(label: '年份', width: 80, numeric: true),
        DataColumnSpec(label: '评分', width: 80, numeric: true),
        DataColumnSpec(label: '播放量', width: 100, numeric: true,
            sortComparator: _sortByPlayCount),
        DataColumnSpec(label: '添加日期', width: 120,
            sortComparator: _sortByAddedAt),
        DataColumnSpec(label: '操作', width: 140),
      ],
      rowBuilder: (ctx, item, selected) {
        final selectedChip = _selectedIds.contains(item.id);
        return DataRow(
          selected: selectedChip,
          onSelectChanged: (v) => _toggleSelection(item.id, v ?? false),
          color: selectedChip
              ? WidgetStateProperty.all(AppTheme.primaryRed.withOpacity(0.08))
              : null,
          cells: [
            DataCell(
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.posterUrl,
                  width: 40,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 56,
                    color: AppTheme.surfaceLight,
                    child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 16),
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 260,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.originalTitle.isNotEmpty ? item.originalTitle : '—',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: item.genres.take(2).map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(g, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DataCell(_buildTypeChip(item.type)),
            DataCell(_buildStatusChip(item.status)),
            DataTextCell('${item.releaseYear}', numeric: true),
            DataCell(
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                  const SizedBox(width: 2),
                  Text(
                    item.rating.toStringAsFixed(1),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            DataTextCell(fmt.format(item.playCount), numeric: true),
            DataTextCell(dateFmt.format(item.addedAt)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    tooltip: '编辑',
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
                    onPressed: () => context.go('/admin/content/edit/${item.id}'),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    tooltip: '删除',
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.primaryRed),
                    onPressed: () => _showDeleteConfirm(item),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      noResultText: '没有匹配的内容，试试调整筛选条件',
    );
  }

  Widget _buildGridView(List<VideoContent> list, NumberFormat fmt, DateFormat dateFmt) {
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text('没有匹配的内容，试试调整筛选条件',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (ctx, cons) {
        final crossCount = cons.maxWidth > 1400 ? 5 : cons.maxWidth > 1000 ? 4 : cons.maxWidth > 600 ? 3 : 2;
        final spacing = 16.0;
        final itemWidth = (cons.maxWidth - spacing * (crossCount - 1)) / crossCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: list.map((item) {
            final selected = _selectedIds.contains(item.id);
            return SizedBox(
              width: itemWidth,
              child: GestureDetector(
                onTap: () => context.go('/admin/content/edit/${item.id}'),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppTheme.primaryRed : AppTheme.divider),
                    boxShadow: selected
                        ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Image.network(
                              item.posterUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.surfaceLight,
                                child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 40),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Checkbox(
                              value: selected,
                              onChanged: (v) {
                                _toggleSelection(item.id, v ?? false);
                              },
                              activeColor: AppTheme.primaryRed,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildStatusChip(item.status),
                          ),
                          if (item.isTopTen)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${item.topTenRank}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildTypeChipSmall(item.type),
                                const Spacer(),
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.releaseYear} · ${fmt.format(item.playCount)} 次播放',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTypeChip(VideoType type) {
    final label = switch (type) {
      VideoType.movie => '电影',
      VideoType.series => '剧集',
      VideoType.tvShow => '节目',
      VideoType.documentary => '纪录片',
    };
    final color = switch (type) {
      VideoType.movie => const Color(0xFF60A5FA),
      VideoType.series => const Color(0xFFA78BFA),
      VideoType.tvShow => const Color(0xFFF59E0B),
      VideoType.documentary => const Color(0xFF34D399),
    };
    return StatusChip(label: label, color: color);
  }

  Widget _buildTypeChipSmall(VideoType type) {
    final label = switch (type) {
      VideoType.movie => '电影',
      VideoType.series => '剧集',
      VideoType.tvShow => '节目',
      VideoType.documentary => '纪录片',
    };
    final color = switch (type) {
      VideoType.movie => const Color(0xFF60A5FA),
      VideoType.series => const Color(0xFFA78BFA),
      VideoType.tvShow => const Color(0xFFF59E0B),
      VideoType.documentary => const Color(0xFF34D399),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatusChip(ContentStatus status) {
    return switch (status) {
      ContentStatus.published => StatusChip.byVariant('已发布', StatusVariant.success),
      ContentStatus.draft => StatusChip.byVariant('草稿', StatusVariant.neutral),
      ContentStatus.unpublished => StatusChip.byVariant('已下线', StatusVariant.warning),
    };
  }

  void _showDeleteConfirm(VideoContent item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('删除内容', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '确定要删除「${item.title}」吗？此操作不可撤销。',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminContentListProvider.notifier).delete(item.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('「${item.title}」已删除'),
                  backgroundColor: AppTheme.surfaceLight,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

int _sortByPlayCount(VideoContent a, VideoContent b) => a.playCount.compareTo(b.playCount);
int _sortByAddedAt(VideoContent a, VideoContent b) => a.addedAt.compareTo(b.addedAt);

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryRed.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppTheme.primaryRed : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
