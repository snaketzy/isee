import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_upload_task.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/upload_progress_tile.dart';

class UploadQueuePage extends ConsumerStatefulWidget {
  final String? id;
  const UploadQueuePage({super.key, this.id});

  @override
  ConsumerState<UploadQueuePage> createState() => _UploadQueuePageState();
}

class _UploadQueuePageState extends ConsumerState<UploadQueuePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  List<MediaUploadTask> _tasks = [];
  final _fileNameController = TextEditingController();
  final _fileSizeController = TextEditingController();
  final _titleController = TextEditingController();

  static const List<String> _tabs = [
    '全部',
    '进行中',
    '已完成',
    '失败',
    '已取消',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshTasks();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      AdminMockRepository.instance.tickUploadTasks();
      _refreshTasks();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _fileNameController.dispose();
    _fileSizeController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _refreshTasks() {
    if (mounted) {
      setState(() {
        _tasks = AdminMockRepository.instance.getAllUploadTasks();
      });
    }
  }

  List<MediaUploadTask> _filterTasks(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _tasks.where((t) => t.stage.isInProgress || t.stage == UploadStage.local || t.stage == UploadStage.r2Done).toList();
      case 2:
        return _tasks.where((t) => t.stage == UploadStage.ready).toList();
      case 3:
        return _tasks.where((t) => t.stage == UploadStage.failed).toList();
      case 4:
        return _tasks.where((t) => t.stage == UploadStage.cancelled).toList();
      default:
        return _tasks;
    }
  }

  int get _total => _tasks.length;
  int get _inProgress => _tasks.where((t) => t.stage.isInProgress || t.stage == UploadStage.local || t.stage == UploadStage.r2Done).length;
  int get _failed => _tasks.where((t) => t.stage == UploadStage.failed).length;

  String get _avgSpeed {
    final speeds = _tasks
        .where((t) => t.currentProgress.speedMbps != null)
        .map((t) => t.currentProgress.speedMbps!)
        .toList();
    if (speeds.isEmpty) return '0 MB/s';
    final avg = speeds.reduce((a, b) => a + b) / speeds.length;
    return '${avg.toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'zh_CN');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildStatGrid(fmt),
        const SizedBox(height: 20),
        _buildTabsAndList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '上传队列',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '监控所有上传任务进度，支持暂停、重试、取消与日志查看',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('上传新视频'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 1200
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
                  title: '任务总数',
                  value: fmt.format(_total),
                  subtitle: '全部上传任务',
                  icon: Icons.queue_rounded,
                  accentColor: const Color(0xFF60A5FA),
                ),
              ),
              SizedBox(
                width: crossCount == 1
                    ? double.infinity
                    : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
                child: StatCard(
                  title: '进行中',
                  value: fmt.format(_inProgress),
                  subtitle: '正在处理的任务',
                  icon: Icons.sync_rounded,
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(
                width: crossCount == 1
                    ? double.infinity
                    : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
                child: StatCard(
                  title: '失败',
                  value: fmt.format(_failed),
                  subtitle: '需要人工处理',
                  icon: Icons.error_outline_rounded,
                  accentColor: const Color(0xFFF87171),
                ),
              ),
              SizedBox(
                width: crossCount == 1
                    ? double.infinity
                    : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
                child: StatCard(
                  title: '平均速度',
                  value: _avgSpeed,
                  subtitle: '进行中任务统计',
                  icon: Icons.speed_rounded,
                  accentColor: const Color(0xFF4ADE80),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabsAndList() {
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primaryRed,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: '${_tabs[0]} (${_tasks.length})'),
                Tab(text: '${_tabs[1]} ($_inProgress)'),
                Tab(text: '${_tabs[2]} (${_tasks.where((t) => t.stage == UploadStage.ready).length})'),
                Tab(text: '${_tabs[3]} ($_failed)'),
                Tab(text: '${_tabs[4]} (${_tasks.where((t) => t.stage == UploadStage.cancelled).length})'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTaskList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final list = _filterTasks(_tabController.index);
    if (list.isEmpty) {
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
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppTheme.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                '暂无任务',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final task = list[i];
        return Padding(
          padding: i == list.length - 1
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 12),
          child: UploadProgressTile(
            task: task,
            onPause: () => _handlePause(task),
            onResume: () => _handleResume(task),
            onRetry: () => _handleRetry(task),
            onCancel: () => _handleCancel(task),
            onViewLogs: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('查看 ${task.fileName} 日志'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handlePause(MediaUploadTask task) {
    AdminMockRepository.instance.updateUploadTask(
      task.id,
      (old) => old.copyWith(stage: UploadStage.paused),
    );
    _refreshTasks();
  }

  void _handleResume(MediaUploadTask task) {
    final lastStage = task.progressHistory.isNotEmpty
        ? task.progressHistory.last.stage
        : UploadStage.uploadingToR2;
    final resumeStage = lastStage.isInProgress ? lastStage : UploadStage.uploadingToR2;
    AdminMockRepository.instance.updateUploadTask(
      task.id,
      (old) => old.copyWith(
        stage: resumeStage,
        progressHistory: [
          ...old.progressHistory,
          UploadStageProgress(
            stage: resumeStage,
            percent: old.currentProgress.percent,
            speedMbps: old.currentProgress.speedMbps,
          ),
        ],
      ),
    );
    _refreshTasks();
  }

  void _handleRetry(MediaUploadTask task) {
    AdminMockRepository.instance.updateUploadTask(
      task.id,
      (old) => old.copyWith(
        stage: UploadStage.uploadingToR2,
        errorMessage: null,
        errorDetail: null,
        retryCount: old.retryCount + 1,
        progressHistory: [
          UploadStageProgress(
            stage: UploadStage.uploadingToR2,
            percent: 0,
          ),
        ],
      ),
    );
    _refreshTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已重试 ${task.fileName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleCancel(MediaUploadTask task) {
    AdminMockRepository.instance.updateUploadTask(
      task.id,
      (old) => old.copyWith(stage: UploadStage.cancelled),
    );
    _refreshTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已取消 ${task.fileName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.divider),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryRed),
            SizedBox(width: 10),
            Text(
              '上传新视频',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _fileNameController,
                label: '文件名 *',
                hint: '例如：new_movie_s01_e01.mp4',
                icon: Icons.insert_drive_file_rounded,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _fileSizeController,
                label: '文件大小 (MB) *',
                hint: '例如：4096',
                icon: Icons.storage_rounded,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _titleController,
                label: '显示标题（可选）',
                hint: '例如：新片 S01E01 首播',
                icon: Icons.title_rounded,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_fileNameController.text.trim().isEmpty ||
                  _fileSizeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写文件名和文件大小')),
                );
                return;
              }
              final size = double.tryParse(_fileSizeController.text.trim()) ?? 1024;
              final now = DateTime.now();
              final newTask = MediaUploadTask(
                id: 'upload_${now.millisecondsSinceEpoch}',
                fileName: _fileNameController.text.trim(),
                displayTitle: _titleController.text.trim().isEmpty
                    ? null
                    : _titleController.text.trim(),
                stage: UploadStage.local,
                createdAt: now,
                fileSizeMb: size,
                createdBy: 'admin_001',
                progressHistory: const [
                  UploadStageProgress(stage: UploadStage.local, percent: 0),
                ],
              );
              AdminMockRepository.instance.addUploadTask(newTask);
              Future.delayed(const Duration(milliseconds: 500), () {
                AdminMockRepository.instance.updateUploadTask(
                  newTask.id,
                  (old) => old.copyWith(
                    stage: UploadStage.uploadingToR2,
                    startedAt: DateTime.now(),
                    progressHistory: [
                      UploadStageProgress(
                        stage: UploadStage.uploadingToR2,
                        percent: 0,
                        speedMbps: 50.0,
                      ),
                    ],
                  ),
                );
              });
              _fileNameController.clear();
              _fileSizeController.clear();
              _titleController.clear();
              Navigator.of(ctx).pop();
              _refreshTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已加入上传队列')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('加入队列'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ],
    );
  }
}
