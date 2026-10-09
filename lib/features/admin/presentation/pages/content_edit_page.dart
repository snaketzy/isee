import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../content/domain/entities/video_content.dart';
import '../../data/providers/admin_content_provider.dart';
import '../../data/repositories/admin_mock_repository.dart';

class ContentEditPage extends ConsumerStatefulWidget {
  final String? id;
  const ContentEditPage({super.key, this.id});

  @override
  ConsumerState<ContentEditPage> createState() => _ContentEditPageState();
}

class _ContentEditPageState extends ConsumerState<ContentEditPage> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _originalTitleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _releaseYearCtrl = TextEditingController();
  final TextEditingController _ratingCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _maturityCtrl = TextEditingController();
  final TextEditingController _castCtrl = TextEditingController();
  final TextEditingController _directorsCtrl = TextEditingController();
  final TextEditingController _posterCtrl = TextEditingController();
  final TextEditingController _backdropCtrl = TextEditingController();
  final TextEditingController _trailerCtrl = TextEditingController();

  VideoType _selectedType = VideoType.movie;
  ContentStatus _selectedStatus = ContentStatus.draft;
  final List<String> _selectedGenres = [];
  bool _isTrending = false;
  bool _isNewRelease = false;
  bool _isTopTen = false;
  int? _topTenRank;
  int _seasonCount = 1;
  int _episodesPerSeason = 10;

  final List<Season> _seasons = [];
  bool _isEditing = false;

  static const _availableGenres = [
    '科幻', '动作', '爱情', '剧情', '喜剧', '悬疑', '恐怖',
    '纪录片', '古装', '冒险', '犯罪', '惊悚', '治愈', '美食',
    '奇幻', '青春', '电竞', '励志', '历史', '自然', '科技',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.id != null;
    if (_isEditing) {
      _loadExisting();
    } else {
      _releaseYearCtrl.text = DateTime.now().year.toString();
      _ratingCtrl.text = '0.0';
      _durationCtrl.text = '120';
      _maturityCtrl.text = 'TV-14';
    }
  }

  void _loadExisting() {
    final existing = AdminMockRepository.instance.getContentById(widget.id!);
    if (existing == null) return;
    _titleCtrl.text = existing.title;
    _originalTitleCtrl.text = existing.originalTitle;
    _descriptionCtrl.text = existing.description;
    _releaseYearCtrl.text = existing.releaseYear.toString();
    _ratingCtrl.text = existing.rating.toString();
    if (existing.duration != null) {
      _durationCtrl.text = existing.duration!.inMinutes.toString();
    }
    _maturityCtrl.text = existing.maturityRating;
    _castCtrl.text = existing.cast.join(', ');
    _directorsCtrl.text = existing.directors.join(', ');
    _posterCtrl.text = existing.posterUrl;
    _backdropCtrl.text = existing.backdropUrl;
    _trailerCtrl.text = existing.trailerUrl ?? '';
    _selectedType = existing.type;
    _selectedStatus = existing.status;
    _selectedGenres.addAll(existing.genres);
    _isTrending = existing.isTrending;
    _isNewRelease = existing.isNewRelease;
    _isTopTen = existing.isTopTen;
    _topTenRank = existing.topTenRank;
    if (existing.isSeries && existing.seasons != null) {
      _seasons.addAll(existing.seasons!);
      _seasonCount = existing.seasons!.length;
      _episodesPerSeason = existing.seasons!.first.episodes.length;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _originalTitleCtrl.dispose();
    _descriptionCtrl.dispose();
    _releaseYearCtrl.dispose();
    _ratingCtrl.dispose();
    _durationCtrl.dispose();
    _maturityCtrl.dispose();
    _castCtrl.dispose();
    _directorsCtrl.dispose();
    _posterCtrl.dispose();
    _backdropCtrl.dispose();
    _trailerCtrl.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _formKey1.currentState?.validate() ?? false;
      case 1:
        return _formKey2.currentState?.validate() ?? false;
      case 2:
        return _formKey3.currentState?.validate() ?? true;
      case 3:
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    setState(() {
      if (_currentStep < 3) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  void _save({bool publishNow = false}) {
    if (!_formKey1.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }
    if (!_formKey2.currentState!.validate()) {
      setState(() => _currentStep = 1);
      return;
    }

    final isSeries = _selectedType == VideoType.series || _selectedType == VideoType.tvShow;
    final seasons = isSeries ? _buildSeasons() : null;
    final totalEpisodes = isSeries
        ? seasons!.fold<int>(0, (sum, s) => sum + s.episodes.length)
        : null;

    final content = VideoContent(
      id: widget.id ?? 'v${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      originalTitle: _originalTitleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      type: _selectedType,
      releaseYear: int.tryParse(_releaseYearCtrl.text) ?? DateTime.now().year,
      duration: _selectedType == VideoType.movie || _selectedType == VideoType.documentary
          ? Duration(minutes: int.tryParse(_durationCtrl.text) ?? 120)
          : null,
      rating: double.tryParse(_ratingCtrl.text) ?? 0.0,
      maturityRating: _maturityCtrl.text.trim(),
      genres: List.unmodifiable(_selectedGenres),
      cast: _castCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      directors: _directorsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      posterUrl: _posterCtrl.text.trim(),
      backdropUrl: _backdropCtrl.text.trim(),
      trailerUrl: _trailerCtrl.text.trim().isEmpty ? null : _trailerCtrl.text.trim(),
      seasons: seasons,
      totalEpisodes: totalEpisodes,
      addedAt: _isEditing
          ? (AdminMockRepository.instance.getContentById(widget.id!)?.addedAt ?? DateTime.now())
          : DateTime.now(),
      isTrending: _isTrending,
      isNewRelease: _isNewRelease,
      isTopTen: _isTopTen,
      topTenRank: _isTopTen ? _topTenRank : null,
      status: publishNow ? ContentStatus.published : _selectedStatus,
    );

    ref.read(adminContentListProvider.notifier).upsert(content);
    final action = publishNow ? '发布' : (_isEditing ? '保存' : '创建');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${content.title}」已$action'),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
    context.go('/admin/content');
  }

  List<Season> _buildSeasons() {
    if (_seasons.isNotEmpty) return _seasons;
    return List.generate(_seasonCount, (sIdx) {
      return Season(
        seasonNumber: sIdx + 1,
        title: '第 ${sIdx + 1} 季',
        description: '',
        episodes: List.generate(_episodesPerSeason, (eIdx) {
          return Episode(
            id: '${widget.id ?? 'new'}_s${sIdx + 1}_e${eIdx + 1}',
            seasonNumber: sIdx + 1,
            episodeNumber: eIdx + 1,
            title: '第 ${eIdx + 1} 集',
            description: '',
            duration: Duration(minutes: 45),
            thumbnailUrl: 'https://picsum.photos/seed/new_se${sIdx + 1}_ep${eIdx + 1}/400/225',
          );
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStepper(),
          const SizedBox(height: 24),
          _buildStepContent(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/admin/content'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? '编辑内容' : '新建内容',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing ? '修改现有视频/剧集的详细信息' : '创建新的视频内容，按步骤填写信息',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    final steps = const ['基本信息', '封面与素材', '季集设置', '发布设置'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryRed
                        : isDone
                            ? const Color(0xFF4ADE80)
                            : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i],
                      style: TextStyle(
                        color: isActive
                            ? AppTheme.primaryRed
                            : isDone
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1) ...[
                  const Spacer(),
                  Container(
                    height: 2,
                    width: 24,
                    color: isDone ? const Color(0xFF4ADE80) : AppTheme.divider,
                  ),
                  const Spacer(),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepBasic();
      case 1:
        return _buildStepAssets();
      case 2:
        return _buildStepSeasons();
      case 3:
        return _buildStepPublish();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionCard(String title, {required Widget child, String? subtitle}) {
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
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int? maxLines,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (required)
              const Text(' *', style: TextStyle(color: AppTheme.primaryRed, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines ?? 1,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator ?? (required
              ? (v) => (v == null || v.trim().isEmpty) ? '请输入$label' : null
              : null),
        ),
      ],
    );
  }

  Widget _buildStepBasic() {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          _buildSectionCard(
            '基础信息',
            subtitle: '填写内容的标题、类型、年份等核心信息',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: '中文标题',
                        controller: _titleCtrl,
                        hint: '例如：星际迷航：新纪元',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: '原名（外文）',
                        controller: _originalTitleCtrl,
                        hint: '例如：Star Trek: New Era',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: '剧情简介',
                  controller: _descriptionCtrl,
                  hint: '请输入内容的剧情介绍...',
                  maxLines: 5,
                  required: true,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '内容类型',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: VideoType.values.map((t) {
                              final selected = _selectedType == t;
                              final label = switch (t) {
                                VideoType.movie => '电影',
                                VideoType.series => '剧集',
                                VideoType.tvShow => '节目',
                                VideoType.documentary => '纪录片',
                              };
                              return GestureDetector(
                                onTap: () => setState(() => _selectedType = t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.primaryRed.withOpacity(0.15) : AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected ? AppTheme.primaryRed : Colors.transparent,
                                      width: selected ? 1.5 : 0,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: selected ? AppTheme.primaryRed : AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: '上映年份',
                        controller: _releaseYearCtrl,
                        hint: '2024',
                        required: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: '评分 (0-10)',
                        controller: _ratingCtrl,
                        hint: '0.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedType == VideoType.movie || _selectedType == VideoType.documentary)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: '时长（分钟）',
                          controller: _durationCtrl,
                          hint: '120',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: '分级',
                          controller: _maturityCtrl,
                          hint: 'TV-14 / TV-MA / TV-PG',
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: '分级',
                          controller: _maturityCtrl,
                          hint: 'TV-14 / TV-MA / TV-PG',
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            '分类与人员',
            subtitle: '选择适用的分类标签，填写演员和导演信息',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '内容分类',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableGenres.map((g) {
                    final selected = _selectedGenres.contains(g);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedGenres.remove(g);
                        } else {
                          _selectedGenres.add(g);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primaryRed.withOpacity(0.15) : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected ? AppTheme.primaryRed : Colors.transparent,
                            width: selected ? 1 : 0,
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: selected ? AppTheme.primaryRed : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: '演员阵容（逗号分隔）',
                        controller: _castCtrl,
                        hint: '张三, 李四, Sarah Chen',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: '导演（逗号分隔）',
                        controller: _directorsCtrl,
                        hint: '王导演, 李副导演',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepAssets() {
    return Form(
      key: _formKey2,
      child: Column(
        children: [
          _buildSectionCard(
            '图片素材',
            subtitle: '上传或填写海报和背景图的 URL 地址',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildInputField(
                            label: '海报图 URL (竖版 2:3)',
                            controller: _posterCtrl,
                            hint: 'https://.../poster.jpg',
                            required: true,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '请输入海报图 URL';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildImagePreview(_posterCtrl.text, 160, 240, Icons.image_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildInputField(
                            label: '背景图 URL (横版 16:9)',
                            controller: _backdropCtrl,
                            hint: 'https://.../backdrop.jpg',
                            required: true,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '请输入背景图 URL';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildImagePreview(_backdropCtrl.text, double.infinity, 220, Icons.wallpaper_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            '视频素材',
            subtitle: '填写预告片地址（正片视频通过上传队列处理）',
            child: Column(
              children: [
                _buildInputField(
                  label: '预告片 URL（可选）',
                  controller: _trailerCtrl,
                  hint: 'https://.../trailer.mp4 或 Mux 播放地址',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '正片视频请通过「上传队列」页面进行上传与转码处理，转码完成后系统会自动关联到内容条目。',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String url, double width, double height, IconData placeholder) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Center(child: Icon(placeholder, color: AppTheme.textMuted, size: 32))
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 28),
                    const SizedBox(height: 4),
                    const Text('图片加载失败', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepSeasons() {
    final isSeries = _selectedType == VideoType.series || _selectedType == VideoType.tvShow;
    return Form(
      key: _formKey3,
      child: Column(
        children: [
          if (!isSeries)
            _buildSectionCard(
              '季集设置',
              subtitle: '当前内容类型为电影/纪录片，无需设置季集',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.movie_creation_rounded, color: AppTheme.textSecondary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '当前选择的是「${_selectedType == VideoType.movie ? '电影' : '纪录片'}」类型，无需配置季和集。若需要多季多集，请回到第一步将类型切换为「剧集」或「节目」。',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildSectionCard(
              '季集结构',
              subtitle: _seasons.isNotEmpty ? '预览已配置的季集信息' : '快速生成季集骨架，后续可在详细页面单独编辑每一集',
              child: _seasons.isNotEmpty ? _buildExistingSeasons() : _buildSeasonGenerator(),
            ),
        ],
      ),
    );
  }

  Widget _buildSeasonGenerator() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: '季数',
                value: _seasonCount,
                onChanged: (v) => setState(() => _seasonCount = v),
                min: 1,
                max: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                label: '每季集数',
                value: _episodesPerSeason,
                onChanged: (v) => setState(() => _episodesPerSeason = v),
                min: 1,
                max: 50,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.amber.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                '将生成 $_seasonCount 季，每季 $_episodesPerSeason 集，共 ${_seasonCount * _episodesPerSeason} 集骨架',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('可保存后再单独编辑每集详情'),
        ),
      ],
    );
  }

  Widget _buildExistingSeasons() {
    return Column(
      children: [
        ExpansionPanelList.radio(
          expandedHeaderPadding: EdgeInsets.zero,
          elevation: 0,
          dividerColor: AppTheme.divider,
          children: _seasons.map((s) {
            return ExpansionPanelRadio(
              value: s.seasonNumber,
              backgroundColor: AppTheme.surfaceLight,
              headerBuilder: (ctx, isExpanded) {
                return ListTile(
                  title: Text(
                    s.title,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '共 ${s.episodes.length} 集',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: s.episodes.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'S${e.seasonNumber.toString().padLeft(2, '0')}E${e.episodeNumber.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.title,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${e.duration.inMinutes} 分钟',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 999,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => onChanged(value > min ? value - 1 : value),
                icon: const Icon(Icons.remove_rounded, color: AppTheme.textSecondary, size: 18),
                constraints: const BoxConstraints(minWidth: 40),
                padding: EdgeInsets.zero,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value < max ? value + 1 : value),
                icon: const Icon(Icons.add_rounded, color: AppTheme.textSecondary, size: 18),
                constraints: const BoxConstraints(minWidth: 40),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPublish() {
    final isSeries = _selectedType == VideoType.series || _selectedType == VideoType.tvShow;
    return Column(
      children: [
        _buildSectionCard(
          '内容标签',
          subtitle: '选择推荐标签，决定内容在前台的展示位置',
          child: Column(
            children: [
              _buildSwitchRow(
                label: '热门推荐',
                desc: '展示在首页「今日热门」区域',
                value: _isTrending,
                onChanged: (v) => setState(() => _isTrending = v),
              ),
              const SizedBox(height: 12),
              _buildSwitchRow(
                label: '新上线',
                desc: '获得「✨ 新上线」专属标签',
                value: _isNewRelease,
                onChanged: (v) => setState(() => _isNewRelease = v),
              ),
              const SizedBox(height: 12),
              _buildSwitchRow(
                label: '加入本周 Top 10 榜单',
                desc: '在 Top 10 排行榜中展示',
                value: _isTopTen,
                onChanged: (v) => setState(() {
                  _isTopTen = v;
                  if (!v) _topTenRank = null;
                }),
              ),
              if (_isTopTen) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: _buildNumberField(
                    label: '榜单排名（1-10）',
                    value: _topTenRank ?? 1,
                    onChanged: (v) => setState(() => _topTenRank = v),
                    min: 1,
                    max: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          '发布状态',
          subtitle: '选择保存后的初始状态',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ContentStatus.values.map((s) {
                  final selected = _selectedStatus == s;
                  final color = switch (s) {
                    ContentStatus.published => const Color(0xFF4ADE80),
                    ContentStatus.draft => AppTheme.textMuted,
                    ContentStatus.unpublished => const Color(0xFFFBBF24),
                  };
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStatus = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.12) : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? color : Colors.transparent,
                          width: selected ? 1.5 : 0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.label,
                            style: TextStyle(
                              color: selected ? color : AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          '内容预览',
          subtitle: '确认填写的关键信息是否正确',
          child: _buildPreviewSummary(isSeries),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryRed.withOpacity(0.7),
            activeThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.divider,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSummary(bool isSeries) {
    final items = <(IconData, String, String)>[
      (Icons.title_rounded, '标题', _titleCtrl.text.isEmpty ? '（未填写）' : _titleCtrl.text),
      (Icons.category_rounded, '类型', switch (_selectedType) {
        VideoType.movie => '电影',
        VideoType.series => '剧集',
        VideoType.tvShow => '节目',
        VideoType.documentary => '纪录片',
      }),
      (Icons.calendar_today_rounded, '年份', _releaseYearCtrl.text),
      if (_selectedGenres.isNotEmpty) (Icons.label_rounded, '分类', _selectedGenres.join(' / ')),
      if (isSeries) (Icons.library_books_rounded, '季集', '$_seasonCount 季 × $_episodesPerSeason 集'),
      (Icons.stars_rounded, '评分', '${_ratingCtrl.text} / 10'),
      (Icons.flag_rounded, '状态', _selectedStatus.label),
    ];
    return Column(
      children: items.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(e.$1, color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                child: Text(
                  e.$2,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  e.$3,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () => context.go('/admin/content'),
          child: const Text('取消'),
        ),
        const SizedBox(width: 12),
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('上一步'),
          ),
        const Spacer(),
        if (_currentStep < 3)
          ElevatedButton.icon(
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('下一步'),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: () => _save(publishNow: false),
            icon: const Icon(Icons.save_rounded, size: 16),
            label: Text(_selectedStatus == ContentStatus.published ? '保存草稿' : '保存'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _save(publishNow: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.publish_rounded, size: 16),
            label: Text(_isEditing ? '保存并发布' : '创建并发布'),
          ),
        ],
      ],
    );
  }
}
