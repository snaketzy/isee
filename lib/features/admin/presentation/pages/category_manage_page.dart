import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../content/domain/entities/video_content.dart';
import '../../data/providers/admin_content_provider.dart';
import '../../data/repositories/admin_mock_repository.dart';

class CategoryManagePage extends ConsumerStatefulWidget {
  final String? id;
  const CategoryManagePage({super.key, this.id});

  @override
  ConsumerState<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage> {
  int? _selectedCategoryIndex;
  final TextEditingController _categoryNameCtrl = TextEditingController();
  final TextEditingController _categoryNewNameCtrl = TextEditingController();
  final TextEditingController _searchVideoCtrl = TextEditingController();
  String _top10Search = '';
  final List<String> _top10Order = [];

  @override
  void initState() {
    super.initState();
    _initTop10Order();
  }

  void _initTop10Order() {
    final allContent = AdminMockRepository.instance.getAllContent();
    final top10 = allContent.where((v) => v.isTopTen).toList()
      ..sort((a, b) => (a.topTenRank ?? 99).compareTo(b.topTenRank ?? 99));
    _top10Order.clear();
    _top10Order.addAll(top10.map((e) => e.id));
  }

  VideoCategory? get _selectedCategory {
    final categories = ref.watch(adminCategoriesProvider);
    if (_selectedCategoryIndex == null ||
        _selectedCategoryIndex! < 0 ||
        _selectedCategoryIndex! >= categories.length) {
      return null;
    }
    return categories[_selectedCategoryIndex!];
  }

  @override
  void dispose() {
    _categoryNameCtrl.dispose();
    _categoryNewNameCtrl.dispose();
    _searchVideoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(adminCategoriesProvider);
    if (_selectedCategoryIndex == null && categories.isNotEmpty) {
      _selectedCategoryIndex = 0;
    }

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: _buildCategoryList(categories)),
                const SizedBox(width: 20),
                Expanded(
                  child: _selectedCategory != null
                      ? _buildCategoryEditor(categories)
                      : _buildEmptyEditor(),
                ),
                const SizedBox(width: 20),
                SizedBox(width: 380, child: _buildTop10Editor()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final categories = ref.watch(adminCategoriesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '分类与榜单管理',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${categories.length} 个分类 · 调整分类顺序、管理分类内容、维护本周 Top 10 榜单',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<VideoCategory> categories) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '分类列表',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add_rounded, color: AppTheme.primaryRed, size: 20),
                  tooltip: '新建分类',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(backgroundColor: AppTheme.primaryRed.withOpacity(0.1)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted, size: 14),
                SizedBox(width: 6),
                Text(
                  '拖拽调整顺序',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: categories.length,
              onReorder: (oldIdx, newIdx) {
                if (newIdx > oldIdx) newIdx--;
                ref.read(adminCategoriesProvider.notifier).reorder(oldIdx, newIdx);
                setState(() {
                  if (_selectedCategoryIndex == oldIdx) {
                    _selectedCategoryIndex = newIdx;
                  } else if (oldIdx < _selectedCategoryIndex! && newIdx >= _selectedCategoryIndex!) {
                    _selectedCategoryIndex = _selectedCategoryIndex! - 1;
                  } else if (oldIdx > _selectedCategoryIndex! && newIdx <= _selectedCategoryIndex!) {
                    _selectedCategoryIndex = _selectedCategoryIndex! + 1;
                  }
                });
              },
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final selected = i == _selectedCategoryIndex;
                return Card(
                  key: ValueKey('cat_${cat.id}_$i'),
                  color: Colors.transparent,
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryIndex = i),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryRed.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? AppTheme.primaryRed.withOpacity(0.4) : Colors.transparent,
                          width: selected ? 1 : 0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: selected ? AppTheme.primaryRed : AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cat.videos.length} 个内容',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEditor() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('请选择一个分类进行编辑', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryEditor(List<VideoCategory> categories) {
    final cat = _selectedCategory!;
    return Column(
      children: [
        _buildCategoryInfoCard(cat, categories),
        const SizedBox(height: 16),
        Expanded(child: _buildCategoryVideosCard(cat)),
      ],
    );
  }

  Widget _buildCategoryInfoCard(VideoCategory cat, List<VideoCategory> categories) {
    _categoryNameCtrl.text = cat.name;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '分类信息',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${cat.id} · 当前包含 ${cat.videos.length} 个内容',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showRenameDialog(cat),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('重命名'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchVideoCtrl,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '搜索可添加的视频内容...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
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
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddVideoDialog(cat),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('添加内容'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryVideosCard(VideoCategory cat) {
    final searchQ = _searchVideoCtrl.text.toLowerCase();
    final videos = cat.videos.where((v) {
      if (searchQ.isEmpty) return true;
      return v.title.toLowerCase().contains(searchQ) ||
          v.originalTitle.toLowerCase().contains(searchQ);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.list_rounded, color: AppTheme.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '分类内容列表（${videos.length}）',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Text(
                  '点击 × 移除',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Expanded(
            child: videos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text('分类暂无内容', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: videos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider, indent: 16),
                    itemBuilder: (ctx, i) {
                      final v = videos[i];
                      return _buildVideoListItem(v, cat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoListItem(VideoContent v, VideoCategory cat) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                v.posterUrl,
                width: 44,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 62,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.title,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel(v.type),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${v.releaseYear} · ⭐ ${v.rating.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeVideoFromCategory(cat, v),
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
              tooltip: '从分类移除',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop10Editor() {
    final List<VideoContent> allContent = ref.watch(adminContentListProvider);
    final top10Items = _top10Order
        .map((id) => allContent.firstWhere(
              (VideoContent c) => c.id == id,
              orElse: () => allContent.isNotEmpty ? allContent.first : VideoContent(
                id: 'placeholder',
                title: '',
                description: '',
                type: VideoType.movie,
                releaseYear: 2024,
                posterUrl: '',
                backdropUrl: '',
                addedAt: DateTime.now(),
              ),
            ))
        .toList();

    final remaining = allContent.where((VideoContent c) {
      if (c.status != ContentStatus.published) return false;
      if (_top10Search.isNotEmpty) {
        final q = _top10Search.toLowerCase();
        if (!c.title.toLowerCase().contains(q)) return false;
      }
      return !_top10Order.contains(c.id);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🏆 本周 Top 10',
                        style: TextStyle(color: AppTheme.primaryRed, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saveTop10,
                      icon: const Icon(Icons.save_rounded, color: Color(0xFF4ADE80), size: 18),
                      tooltip: '保存榜单顺序',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF4ADE80).withOpacity(0.1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '拖拽列表项调整榜单排名，从下方「候选内容」拖拽添加',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: top10Items.length,
              onReorder: (oldIdx, newIdx) {
                if (newIdx > oldIdx) newIdx--;
                setState(() {
                  final id = _top10Order.removeAt(oldIdx);
                  _top10Order.insert(newIdx, id);
                  for (int i = 0; i < top10Items.length; i++) {
                    final idx = _top10Order.indexOf(top10Items[i].id);
                    if (idx >= 0) {
                      final c = top10Items[i];
                      ref.read(adminContentListProvider.notifier).upsert(c.copyWith(
                        isTopTen: true,
                        topTenRank: idx + 1,
                      ));
                    }
                  }
                });
              },
              itemBuilder: (ctx, i) {
                final v = top10Items[i];
                final rank = i + 1;
                Color rankColor = AppTheme.textMuted;
                if (rank == 1) rankColor = const Color(0xFFFBBF24);
                if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                if (rank == 3) rankColor = const Color(0xFFCD7F32);
                return Card(
                  key: ValueKey('top10_${v.id}'),
                  color: Colors.transparent,
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: rankColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: rankColor.withOpacity(0.5)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: TextStyle(color: rankColor, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted, size: 14),
                        const SizedBox(width: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            v.posterUrl,
                            width: 32,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32,
                              height: 44,
                              color: AppTheme.surfaceDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.title,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '⭐ ${v.rating.toStringAsFixed(1)} · ${NumberFormat('#,##0', 'zh_CN').format(v.playCount)} 次',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _top10Order.remove(v.id);
                              final notifier = ref.read(adminContentListProvider.notifier);
                              notifier.upsert(v.copyWith(isTopTen: false, topTenRank: null));
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textMuted, size: 16),
                          tooltip: '移出榜单',
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: TextField(
              onChanged: (v) => setState(() => _top10Search = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索候选内容...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 16),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              '候选内容（${remaining.length}）· 点击 + 添加到榜单',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
          SizedBox(
            height: 200,
            child: remaining.isEmpty
                ? const Center(
                    child: Text('没有符合条件的候选内容', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: remaining.length > 8 ? 8 : remaining.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (ctx, i) {
                      final v = remaining[i];
                      return InkWell(
                        onTap: _top10Order.length >= 10
                            ? null
                            : () {
                                if (_top10Order.length >= 10) return;
                                setState(() {
                                  _top10Order.add(v.id);
                                  final notifier = ref.read(adminContentListProvider.notifier);
                                  notifier.upsert(v.copyWith(isTopTen: true, topTenRank: _top10Order.length));
                                });
                              },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  v.posterUrl,
                                  width: 28,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 28, height: 40, color: AppTheme.surfaceDark),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  v.title,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: _top10Order.length >= 10 ? AppTheme.textMuted : AppTheme.primaryRed,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(VideoType t) => switch (t) {
    VideoType.movie => '电影',
    VideoType.series => '剧集',
    VideoType.tvShow => '节目',
    VideoType.documentary => '纪录片',
  };

  void _showRenameDialog(VideoCategory cat) {
    _categoryNewNameCtrl.text = cat.name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('重命名分类', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: _categoryNewNameCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: '输入新的分类名称',
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final newName = _categoryNewNameCtrl.text.trim();
              if (newName.isEmpty) return;
              final updated = VideoCategory(id: cat.id, name: newName, videos: cat.videos);
              ref.read(adminCategoriesProvider.notifier).update(updated);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('分类已重命名为「$newName」'), backgroundColor: AppTheme.surfaceLight),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _categoryNewNameCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('新建分类', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: _categoryNewNameCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: '例如：🎬 悬疑精选',
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final name = _categoryNewNameCtrl.text.trim();
              if (name.isEmpty) return;
              final newCat = VideoCategory(
                id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                videos: const [],
              );
              ref.read(adminCategoriesProvider.notifier).update(newCat);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已创建分类「$name」'), backgroundColor: AppTheme.surfaceLight),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _removeVideoFromCategory(VideoCategory cat, VideoContent video) {
    final newVideos = List<VideoContent>.from(cat.videos)..removeWhere((v) => v.id == video.id);
    final updated = VideoCategory(id: cat.id, name: cat.name, videos: newVideos);
    ref.read(adminCategoriesProvider.notifier).update(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将「${video.title}」从「${cat.name}」移除'),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
  }

  void _showAddVideoDialog(VideoCategory cat) {
    final allContent = AdminMockRepository.instance.getAllContent();
    final notInCat = allContent.where((v) => !cat.videos.any((cv) => cv.id == v.id)).toList();
    String localSearch = '';
    final selected = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = notInCat.where((v) {
            if (localSearch.isEmpty) return true;
            final q = localSearch.toLowerCase();
            return v.title.toLowerCase().contains(q) ||
                v.originalTitle.toLowerCase().contains(q) ||
                v.genres.any((g) => g.toLowerCase().contains(q));
          }).toList();
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Text('添加内容到「', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
                Text(cat.name, style: const TextStyle(color: AppTheme.primaryRed, fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('」', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 480,
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setDialogState(() => localSearch = v),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '搜索标题、分类...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('没有匹配的内容', style: TextStyle(color: AppTheme.textMuted)))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
                            itemBuilder: (_, i) {
                              final v = filtered[i];
                              final isSel = selected.contains(v.id);
                              return InkWell(
                                onTap: () => setDialogState(() {
                                  if (isSel) {
                                    selected.remove(v.id);
                                  } else {
                                    selected.add(v.id);
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppTheme.primaryRed.withOpacity(0.08) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSel,
                                        onChanged: (_) => setDialogState(() {
                                          if (isSel) {
                                            selected.remove(v.id);
                                          } else {
                                            selected.add(v.id);
                                          }
                                        }),
                                        activeColor: AppTheme.primaryRed,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          v.posterUrl,
                                          width: 40,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 40,
                                            height: 56,
                                            color: AppTheme.surfaceLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              v.title,
                                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_typeLabel(v.type)} · ${v.releaseYear} · ⭐ ${v.rating.toStringAsFixed(1)}',
                                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              Text('已选 ${selected.length} 项', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const Spacer(),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
              ElevatedButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final toAdd = notInCat.where((v) => selected.contains(v.id)).toList();
                        final newVideos = List<VideoContent>.from(cat.videos)..addAll(toAdd);
                        final updated = VideoCategory(id: cat.id, name: cat.name, videos: newVideos);
                        ref.read(adminCategoriesProvider.notifier).update(updated);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已添加 ${toAdd.length} 项内容到「${cat.name}」'),
                            backgroundColor: AppTheme.surfaceLight,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primaryRed.withOpacity(0.35),
                ),
                child: Text('添加 (${selected.length})'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveTop10() {
    final notifier = ref.read(adminContentListProvider.notifier);
    for (int i = 0; i < _top10Order.length; i++) {
      final id = _top10Order[i];
      final content = AdminMockRepository.instance.getContentById(id);
      if (content != null) {
        notifier.upsert(content.copyWith(isTopTen: true, topTenRank: i + 1));
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Top 10 榜单顺序已保存'), backgroundColor: AppTheme.surfaceLight),
    );
  }
}
