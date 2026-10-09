import 'dart:math';

import '../../../../core/data/mock_data.dart';
import '../../../../core/models/video_quality.dart';
import '../../../../features/content/domain/entities/video_content.dart';
import '../../../../features/user/domain/entities/user_profile.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/media_upload_task.dart';
import '../../domain/entities/system_config.dart';

class AdminMockRepository {
  AdminMockRepository._internal();
  static final AdminMockRepository instance = AdminMockRepository._internal();

  static String _img(String id, {int w = 400, int h = 600}) =>
      'https://picsum.photos/seed/$id/$w/$h';

  final Random _random = Random();
  final List<VideoContent> _contentList = List.from(MockData.getAllVideos());
  final List<AdminUser> _adminUsers = _buildDefaultAdminUsers();
  List<UserProfile> _users = _buildMockUsers();
  List<MediaUploadTask> _uploadTasks = _buildDefaultUploadTasks();
  final List<MuxAssetInfo> _muxAssets = _buildDefaultMuxAssets();
  List<MembershipPlan> _membershipPlans = List.from(MockData.membershipPlans);
  List<VideoCategory> _categories = List.from(MockData.categories);

  static List<AdminUser> _buildDefaultAdminUsers() {
    final now = DateTime.now();
    return [
      AdminUser(
        id: 'admin_001',
        email: 'admin@isee.video',
        displayName: '超级管理员',
        avatarUrl: _img('admin_001', w: 200, h: 200),
        role: AdminRole.superAdmin,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 365)),
        lastLoginAt: now.subtract(const Duration(hours: 2)),
        lastLoginIp: '192.168.1.100',
        loginCount: 1284,
      ),
      AdminUser(
        id: 'admin_002',
        email: 'editor@isee.video',
        displayName: '内容编辑-小王',
        avatarUrl: _img('admin_002', w: 200, h: 200),
        role: AdminRole.contentEditor,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 180)),
        lastLoginAt: now.subtract(const Duration(minutes: 45)),
        lastLoginIp: '192.168.1.101',
        loginCount: 421,
      ),
      AdminUser(
        id: 'admin_003',
        email: 'analyst@isee.video',
        displayName: '运营分析师-Lisa',
        avatarUrl: _img('admin_003', w: 200, h: 200),
        role: AdminRole.analyst,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 90)),
        lastLoginAt: now.subtract(const Duration(days: 1)),
        lastLoginIp: '192.168.1.102',
        loginCount: 156,
      ),
    ];
  }

  static List<UserProfile> _buildMockUsers() {
    final now = DateTime.now();
    final List<UserProfile> users = [];
    final plans = MockData.membershipPlans;
    final names = [
      '小明', '张三', '李四', '王五', '赵六', '陈七', '周八', '吴九', '郑十', '孙十一',
      '李雷', '韩梅梅', 'Lucy', 'Lily', 'Tom', 'Jerry', 'Alice', 'Bob', 'Charlie', 'David',
      'Emma', 'Sophia', 'Olivia', 'Ava', 'Isabella', 'Mia', 'Amelia', 'Harper', 'Evelyn', 'Abigail',
      'James', 'William', 'Benjamin', 'Lucas', 'Henry', 'Alexander', 'Mason', 'Michael', 'Ethan', 'Daniel',
      '郭靖', '黄蓉', '杨过', '小龙女', '张无忌', '赵敏', '令狐冲', '任盈盈', '乔峰', '阿朱',
    ];
    for (int i = 0; i < 50; i++) {
      final planIndex = i % 3;
      final plan = plans[planIndex];
      final tier = plan.tier;
      final registeredAt = now.subtract(Duration(days: Random().nextInt(365)));
      final daysSinceRegister = now.difference(registeredAt).inDays;
      final startOffset = daysSinceRegister > 30 ? 30 : 0;
      final expireDays = 30 + Random().nextInt(330);
      users.add(UserProfile(
        id: 'user_${(i + 1).toString().padLeft(3, '0')}',
        email: 'user${i + 1}@isee.video',
        phone: '+86 138****${(1000 + i).toString().padLeft(4, '0')}',
        displayName: names[i % names.length] + (i >= names.length ? '${i ~/ names.length}' : ''),
        avatarUrl: _img('user_${i + 1}', w: 200, h: 200),
        language: i % 5 == 0 ? 'en-US' : 'zh-CN',
        preferredQuality: tier == MembershipTier.premium
            ? VideoQuality.q4k
            : tier == MembershipTier.standard
                ? VideoQuality.q1080p
                : VideoQuality.q720p,
        autoplayNext: i % 7 != 0,
        autoplayTrailers: i % 3 != 0,
        myListIds: MockData.getAllVideos()
            .sublist(0, Random().nextInt(8) + 1)
            .map((v) => v.id)
            .toList(),
        watchProgress: const {},
        membership: UserMembership(
          tier: tier,
          plan: plan,
          startDate: now.subtract(Duration(days: startOffset)),
          expireDate: now.add(Duration(days: expireDays)),
          isActive: i % 23 != 0,
          isAutoRenew: i % 4 != 0,
          paymentMethod: i % 3 == 0
              ? 'Stripe •••• 4242'
              : i % 3 == 1
                  ? 'PayPal • user***@paypal.com'
                  : 'USDT • 0x1234...abcd',
          history: [
            SubscriptionEvent(
              id: 'sub_${i}_1',
              type: 'subscribe',
              date: now.subtract(Duration(days: startOffset)),
              description: '开通${plan.name}',
              amount: plan.monthlyPrice,
            ),
            if (startOffset > 15)
              SubscriptionEvent(
                id: 'sub_${i}_2',
                type: 'renew',
                date: now.subtract(const Duration(days: 15)),
                description: '续费${plan.name}',
                amount: plan.monthlyPrice,
              ),
          ],
        ),
        registeredAt: registeredAt,
        lastLoginAt: now.subtract(Duration(hours: Random().nextInt(24 * 7))),
        status: i % 47 == 0 ? UserStatus.frozen : UserStatus.active,
        totalWatchMinutes: Random().nextInt(50000),
        loginCount: Random().nextInt(500) + 1,
        region: i % 4 == 0
            ? '北京'
            : i % 4 == 1
                ? '上海'
                : i % 4 == 2
                    ? '深圳'
                    : '广州',
        recentWatchHistory: _buildWatchHistory(i),
      ));
    }
    return users;
  }

  static List<WatchHistoryItem> _buildWatchHistory(int seed) {
    final rand = Random(seed + 42);
    final videos = MockData.getAllVideos();
    final List<WatchHistoryItem> list = [];
    for (int i = 0; i < 8; i++) {
      final v = videos[rand.nextInt(videos.length)];
      list.add(WatchHistoryItem(
        videoId: v.id,
        episodeId: v.isSeries && v.seasons != null && v.seasons!.isNotEmpty
            ? v.seasons!.first.episodes[rand.nextInt(v.seasons!.first.episodes.length)].id
            : null,
        videoTitle: v.title,
        watchedAt: DateTime.now().subtract(Duration(hours: rand.nextInt(24 * 5))),
        progress: rand.nextDouble(),
        watchMinutes: rand.nextInt(120) + 1,
      ));
    }
    return list;
  }

  static List<MediaUploadTask> _buildDefaultUploadTasks() {
    final now = DateTime.now();
    return [
      MediaUploadTask(
        id: 'upload_001',
        fileName: 'test1.mp4',
        displayTitle: '测试视频 1 - 示例',
        stage: UploadStage.ready,
        createdAt: now.subtract(const Duration(days: 5)),
        startedAt: now.subtract(const Duration(days: 5, hours: 1)),
        completedAt: now.subtract(const Duration(days: 4, hours: 22)),
        muxAssetId: 'XceDtWCR2F01InyWrAcI00JeLtWCDPcOjN4g01im00Y0100',
        muxPlaybackId: 'XceDtWCR2F01InyWrAcI00JeLtWCDPcOjN4g01im00Y0100FQ',
        videoContentId: 'v002',
        progressHistory: [
          UploadStageProgress(stage: UploadStage.ready, percent: 100),
        ],
        fileSizeMb: 2048,
        createdBy: 'admin_001',
      ),
      MediaUploadTask(
        id: 'upload_002',
        fileName: 'epic_sci_fi_movie_4k.mov',
        displayTitle: '星际穿越 4K 修复版',
        stage: UploadStage.transcoding,
        priority: UploadPriority.high,
        createdAt: now.subtract(const Duration(hours: 4)),
        startedAt: now.subtract(const Duration(hours: 3, minutes: 45)),
        progressHistory: [
          UploadStageProgress(
            stage: UploadStage.uploadingToR2,
            percent: 100,
            speedMbps: 85.4,
            transferredMb: 15360,
            totalMb: 15360,
          ),
          UploadStageProgress(
            stage: UploadStage.transcoding,
            percent: 68,
          ),
        ],
        fileSizeMb: 15360,
        createdBy: 'admin_001',
      ),
      MediaUploadTask(
        id: 'upload_003',
        fileName: 'documentary_ocean_s01_e05.mp4',
        displayTitle: '深蓝海洋 S01E05',
        stage: UploadStage.uploadingToR2,
        priority: UploadPriority.normal,
        createdAt: now.subtract(const Duration(minutes: 35)),
        startedAt: now.subtract(const Duration(minutes: 30)),
        progressHistory: [
          UploadStageProgress(
            stage: UploadStage.uploadingToR2,
            percent: 42,
            speedMbps: 32.1,
            transferredMb: 1344,
            totalMb: 3200,
            etaSeconds: 480,
          ),
        ],
        fileSizeMb: 3200,
        createdBy: 'admin_002',
      ),
      MediaUploadTask(
        id: 'upload_004',
        fileName: 'comedy_special_live.mp4',
        displayTitle: '脱口秀专场 - 欢乐之夜',
        stage: UploadStage.pullingToMux,
        priority: UploadPriority.urgent,
        createdAt: now.subtract(const Duration(hours: 2)),
        startedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
        progressHistory: [
          UploadStageProgress(
            stage: UploadStage.uploadingToR2,
            percent: 100,
            speedMbps: 120.0,
            transferredMb: 8192,
            totalMb: 8192,
          ),
          UploadStageProgress(
            stage: UploadStage.pullingToMux,
            percent: 25,
          ),
        ],
        fileSizeMb: 8192,
        createdBy: 'admin_002',
      ),
      MediaUploadTask(
        id: 'upload_005',
        fileName: 'horror_remastered_s02_e01.mkv',
        displayTitle: '暗影猎手 S02E01 未删减版',
        stage: UploadStage.failed,
        priority: UploadPriority.high,
        createdAt: now.subtract(const Duration(days: 1)),
        startedAt: now.subtract(const Duration(days: 1, hours: 1)),
        errorMessage: 'Mux 拉取返回 403 Forbidden',
        errorDetail:
            'R2 public bucket access disabled; please enable R2.dev public access and retry.',
        retryCount: 2,
        progressHistory: [
          UploadStageProgress(
            stage: UploadStage.uploadingToR2,
            percent: 100,
            transferredMb: 6144,
            totalMb: 6144,
          ),
          UploadStageProgress(stage: UploadStage.failed, percent: 30),
        ],
        fileSizeMb: 6144,
        createdBy: 'admin_001',
      ),
      MediaUploadTask(
        id: 'upload_006',
        fileName: 'anime_film_2024.mp4',
        displayTitle: '剧场版：星辰大海（待上传）',
        stage: UploadStage.local,
        priority: UploadPriority.low,
        createdAt: now.subtract(const Duration(minutes: 5)),
        fileSizeMb: 4096,
        createdBy: 'admin_002',
      ),
    ];
  }

  static List<MuxAssetInfo> _buildDefaultMuxAssets() {
    final now = DateTime.now();
    return [
      MuxAssetInfo(
        assetId: 'XceDtWCR2F01InyWrAcI00JeLtWCDPcOjN4g01im00Y0100',
        playbackId: 'XceDtWCR2F01InyWrAcI00JeLtWCDPcOjN4g01im00Y0100FQ',
        videoContentId: 'v002',
        title: '暗影猎手 - 预告片',
        status: 'ready',
        maxResolution: '1080p',
        availableResolutions: const ['360p', '480p', '540p', '720p', '1080p'],
        duration: const Duration(minutes: 135),
        fileSizeMb: 2048,
        createdAt: now.subtract(const Duration(days: 7)),
        readyAt: now.subtract(const Duration(days: 6, hours: 22)),
        playCount: 4821,
        bandwidthGb: 1248.3,
      ),
      MuxAssetInfo(
        assetId: 'asset_s002_abcdef123',
        playbackId: 'asset_s002_playback_xyz789',
        videoContentId: 'v001',
        title: '星际迷航：新纪元 S01E01',
        status: 'ready',
        maxResolution: '2160p',
        availableResolutions: const ['360p', '480p', '540p', '720p', '1080p', '1440p', '2160p'],
        duration: const Duration(minutes: 52),
        fileSizeMb: 8192,
        createdAt: now.subtract(const Duration(days: 30)),
        readyAt: now.subtract(const Duration(days: 29, hours: 20)),
        playCount: 18342,
        bandwidthGb: 4521.7,
      ),
      MuxAssetInfo(
        assetId: 'asset_movie_003_abc',
        playbackId: 'movie_003_pb_123456',
        videoContentId: 'v008',
        title: '机械心脏 - 主片',
        status: 'ready',
        maxResolution: '1080p',
        availableResolutions: const ['360p', '480p', '720p', '1080p'],
        duration: const Duration(minutes: 142),
        fileSizeMb: 5120,
        createdAt: now.subtract(const Duration(days: 3)),
        readyAt: now.subtract(const Duration(days: 2, hours: 18)),
        playCount: 2891,
        bandwidthGb: 612.1,
      ),
      MuxAssetInfo(
        assetId: 'asset_trans_004',
        playbackId: 'asset_trans_004_pb',
        status: 'preparing',
        maxResolution: '2160p',
        availableResolutions: const [],
        duration: const Duration(minutes: 168),
        fileSizeMb: 15360,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      MuxAssetInfo(
        assetId: 'asset_errored_005',
        playbackId: 'asset_errored_005_pb',
        status: 'errored',
        maxResolution: 'unknown',
        availableResolutions: const [],
        duration: Duration.zero,
        fileSizeMb: 6144,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  // ---------- Content ----------
  List<VideoContent> getAllContent({bool includeUnpublished = true}) {
    if (includeUnpublished) return List.unmodifiable(_contentList);
    return List.unmodifiable(
        _contentList.where((v) => v.status == ContentStatus.published));
  }

  VideoContent? getContentById(String id) {
    for (final v in _contentList) {
      if (v.id == id) return v;
    }
    return null;
  }

  void upsertContent(VideoContent content) {
    final idx = _contentList.indexWhere((v) => v.id == content.id);
    final updated = content.copyWith(updatedAt: DateTime.now());
    if (idx >= 0) {
      _contentList[idx] = updated;
    } else {
      _contentList.insert(0, updated);
    }
  }

  void deleteContent(String id) {
    _contentList.removeWhere((v) => v.id == id);
  }

  void updateContentStatus(List<String> ids, ContentStatus status) {
    for (int i = 0; i < _contentList.length; i++) {
      if (ids.contains(_contentList[i].id)) {
        _contentList[i] = _contentList[i]
            .copyWith(status: status, updatedAt: DateTime.now());
      }
    }
  }

  // ---------- Categories ----------
  List<VideoCategory> getAllCategories() => List.unmodifiable(_categories);

  void updateCategory(VideoCategory category) {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
    } else {
      _categories.add(category);
    }
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _categories.length) return;
    if (newIndex < 0 || newIndex >= _categories.length) return;
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
  }

  // ---------- Admin Auth ----------
  AdminAuthState authenticate(String email, String password) {
    final emailLower = email.trim().toLowerCase();
    final admin = _adminUsers
        .where((a) => a.email.toLowerCase() == emailLower)
        .firstOrNull;
    if (admin == null || !admin.isActive) {
      return const AdminAuthState(
        isAuthenticated: false,
        errorMessage: '邮箱或密码错误',
      );
    }
    // Mock 密码校验：admin@isee.video / admin123；其他用户用各自邮箱前缀 + 123
    final expectedPassword = emailLower.startsWith('admin@')
        ? 'admin123'
        : emailLower.startsWith('editor@')
            ? 'editor123'
            : 'analyst123';
    if (password != expectedPassword) {
      return const AdminAuthState(
        isAuthenticated: false,
        errorMessage: '邮箱或密码错误',
      );
    }
    final idx = _adminUsers.indexWhere((a) => a.id == admin.id);
    final updated = admin.copyWith(
      lastLoginAt: DateTime.now(),
      loginCount: admin.loginCount + 1,
    );
    if (idx >= 0) _adminUsers[idx] = updated;
    final token = 'mock_token_${admin.id}_${DateTime.now().millisecondsSinceEpoch}';
    return AdminAuthState(
      user: updated,
      token: token,
      isAuthenticated: true,
    );
  }

  AdminUser? getAdminById(String id) {
    for (final a in _adminUsers) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<AdminUser> getAllAdminUsers() => List.unmodifiable(_adminUsers);

  void upsertAdminUser(AdminUser user) {
    final idx = _adminUsers.indexWhere((a) => a.id == user.id);
    if (idx >= 0) {
      _adminUsers[idx] = user;
    } else {
      _adminUsers.add(user);
    }
  }

  // ---------- C 端用户 ----------
  List<UserProfile> getAllUsers() => List.unmodifiable(_users);

  UserProfile? getUserById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  void updateUser(String id, UserProfile Function(UserProfile old) updater) {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx < 0) return;
    _users[idx] = updater(_users[idx]);
  }

  void batchGiftDays(List<String> userIds, int days) {
    for (final uid in userIds) {
      updateUser(uid, (old) {
        final newExpire = old.membership.expireDate.add(Duration(days: days));
        final newHistory = [
          ...old.membership.history,
          SubscriptionEvent(
            id: 'gift_${uid}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'gift',
            date: DateTime.now(),
            description: '运营赠送 $days 天会员',
            amount: 0,
          ),
        ];
        return old.copyWith(
          membership: old.membership.copyWith(
            expireDate: newExpire,
            isActive: true,
            history: newHistory,
          ),
        );
      });
    }
  }

  void toggleUserFrozen(String userId) {
    updateUser(userId, (old) {
      final newStatus = old.status == UserStatus.frozen
          ? UserStatus.active
          : UserStatus.frozen;
      final newHistory = [
        ...old.membership.history,
        SubscriptionEvent(
          id: 'status_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          type: newStatus == UserStatus.frozen ? 'freeze' : 'unfreeze',
          date: DateTime.now(),
          description: newStatus == UserStatus.frozen ? '账号被冻结' : '账号已解冻',
        ),
      ];
      return old.copyWith(
        status: newStatus,
        membership: old.membership.copyWith(history: newHistory),
      );
    });
  }

  void renewUserMembership(String userId, {int days = 30}) {
    updateUser(userId, (old) {
      final plan = old.membership.plan;
      final newExpire = old.membership.expireDate.add(Duration(days: days));
      final newHistory = [
        ...old.membership.history,
        SubscriptionEvent(
          id: 'renew_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          type: 'renew',
          date: DateTime.now(),
          description: '手动续费 $days 天',
          amount: plan.monthlyPrice * (days / 30),
        ),
      ];
      return old.copyWith(
        membership: old.membership.copyWith(
          expireDate: newExpire,
          isActive: true,
          history: newHistory,
        ),
      );
    });
  }

  void upgradeUserPlan(String userId, MembershipTier newTier) {
    final plans = getMembershipPlans();
    final newPlan = plans.firstWhere((p) => p.tier == newTier);
    updateUser(userId, (old) {
      final newHistory = [
        ...old.membership.history,
        SubscriptionEvent(
          id: 'upgrade_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          type: 'upgrade',
          date: DateTime.now(),
          description: '升级套餐至 ${newPlan.name}',
          amount: newPlan.monthlyPrice,
        ),
      ];
      return old.copyWith(
        membership: old.membership.copyWith(
          tier: newTier,
          plan: newPlan,
          history: newHistory,
        ),
      );
    });
  }

  void toggleUserAutoRenew(String userId) {
    updateUser(userId, (old) {
      return old.copyWith(
        membership: old.membership.copyWith(
          isAutoRenew: !old.membership.isAutoRenew,
        ),
      );
    });
  }

  void sendEmailNotification(List<String> userIds, String subject) {
    // Mock 发邮件，这里仅记录
  }

  // ---------- Membership plans ----------
  List<MembershipPlan> getMembershipPlans() => List.unmodifiable(_membershipPlans);

  void updateMembershipPlan(MembershipPlan plan) {
    final idx = _membershipPlans.indexWhere((p) => p.id == plan.id);
    final updated = plan.copyWith(updatedAt: DateTime.now());
    if (idx >= 0) {
      _membershipPlans[idx] = updated;
    } else {
      _membershipPlans.add(updated);
    }
    MockData.updateMembershipPlans(_membershipPlans);
  }

  // ---------- Upload tasks ----------
  List<MediaUploadTask> getAllUploadTasks() => List.unmodifiable(_uploadTasks);

  MediaUploadTask? getUploadTaskById(String id) {
    for (final t in _uploadTasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void addUploadTask(MediaUploadTask task) {
    _uploadTasks.insert(0, task);
  }

  void updateUploadTask(String id, MediaUploadTask Function(MediaUploadTask old) updater) {
    final idx = _uploadTasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    _uploadTasks[idx] = updater(_uploadTasks[idx]);
  }

  void tickUploadTasks() {
    for (int i = 0; i < _uploadTasks.length; i++) {
      final t = _uploadTasks[i];
      if (t.stage == UploadStage.local ||
          t.stage == UploadStage.paused ||
          t.stage == UploadStage.cancelled ||
          t.stage == UploadStage.ready ||
          t.stage == UploadStage.failed) {
        continue;
      }
      final cur = t.currentProgress;
      final newPercent = (cur.percent + _random.nextInt(5) + 1).clamp(0, 100);
      final newHistory = List<UploadStageProgress>.from(t.progressHistory);
      if (newHistory.isNotEmpty) {
        newHistory[newHistory.length - 1] =
            cur.copyWithPercent(newPercent, t.currentProgress.stage);
      }
      UploadStage newStage = t.stage;
      if (newPercent >= 100) {
        switch (t.stage) {
          case UploadStage.uploadingToR2:
            newStage = UploadStage.r2Done;
            newHistory.add(UploadStageProgress(
              stage: UploadStage.r2Done,
              percent: 100,
              transferredMb: t.fileSizeMb,
              totalMb: t.fileSizeMb,
            ));
            Future.delayed(const Duration(milliseconds: 200), () {
              updateUploadTask(t.id, (old) => old.copyWith(
                    stage: UploadStage.pullingToMux,
                    progressHistory: [
                      ...old.progressHistory,
                      UploadStageProgress(stage: UploadStage.pullingToMux, percent: 0),
                    ],
                  ));
            });
            break;
          case UploadStage.pullingToMux:
            newStage = UploadStage.transcoding;
            newHistory.add(UploadStageProgress(
              stage: UploadStage.transcoding,
              percent: 0,
            ));
            break;
          case UploadStage.transcoding:
            newStage = UploadStage.ready;
            newHistory
                .add(UploadStageProgress(stage: UploadStage.ready, percent: 100));
            _uploadTasks[i] = t.copyWith(
              stage: newStage,
              progressHistory: newHistory,
              completedAt: DateTime.now(),
              muxAssetId: 'mux_asset_${t.id}',
              muxPlaybackId: 'pb_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
            );
            continue;
          default:
            break;
        }
      }
      if (newPercent < 100) {
        final last = newHistory.last;
        final newSpeed = (last.speedMbps ?? 50) + (_random.nextDouble() - 0.5) * 20;
        newHistory[newHistory.length - 1] = UploadStageProgress(
          stage: last.stage,
          percent: newPercent,
          speedMbps: newSpeed.clamp(0.5, 200),
          transferredMb: t.fileSizeMb * (newPercent / 100),
          totalMb: t.fileSizeMb,
          etaSeconds: last.stage == UploadStage.uploadingToR2 && newSpeed > 0
              ? ((t.fileSizeMb * (100 - newPercent) / 100) / newSpeed * 8).round()
              : last.etaSeconds,
        );
      }
      _uploadTasks[i] = t.copyWith(
        stage: newStage,
        progressHistory: newHistory,
      );
    }
  }

  // ---------- Mux assets ----------
  List<MuxAssetInfo> getAllMuxAssets() => List.unmodifiable(_muxAssets);

  // ---------- R2 storage ----------
  R2StorageStats getR2Stats() {
    return R2StorageStats(
      totalSizeGb: 2184.7,
      totalFiles: 1842,
      monthlyEgressGb: 38412.2,
      totalVideos: 412,
      monthlyCostEstimate: 0.0,
    );
  }

  List<R2FileItem> browseR2Folder(String folderKey) {
    final now = DateTime.now();
    final base = folderKey.isEmpty ? '' : folderKey;
    final folders = base.isEmpty
        ? const ['videos/', 'posters/', 'trailers/', 'thumbnails/', 'temp/']
        : <String>[];
    final files = <R2FileItem>[];
    for (final f in folders) {
      files.add(R2FileItem(
        key: base + f,
        name: f.replaceAll('/', ''),
        parentKey: base.isEmpty ? null : base,
        isFolder: true,
        lastModified: now.subtract(const Duration(days: 7)),
        publicUrl: 'https://cdn.isee.video/$base$f',
      ));
    }
    if (base == 'videos/') {
      for (int i = 1; i <= 24; i++) {
        final name = 'video_${i.toString().padLeft(3, '0')}.mp4';
        files.add(R2FileItem(
          key: 'videos/$name',
          name: name,
          parentKey: 'videos/',
          sizeMb: 512.0 + _random.nextDouble() * 8000,
          lastModified: now.subtract(Duration(hours: _random.nextInt(24 * 14))),
          etag: '"etag_${i}_${DateTime.now().millisecondsSinceEpoch}"',
          publicUrl: 'https://cdn.isee.video/videos/$name',
        ));
      }
    } else if (base == 'posters/') {
      for (int i = 1; i <= 16; i++) {
        final name = 'poster_v$i.jpg';
        files.add(R2FileItem(
          key: 'posters/$name',
          name: name,
          parentKey: 'posters/',
          sizeMb: 0.8 + _random.nextDouble() * 2,
          lastModified: now.subtract(Duration(days: _random.nextInt(90))),
          etag: '"etag_poster_$i"',
          publicUrl: 'https://cdn.isee.video/posters/$name',
        ));
      }
    } else if (base.isEmpty) {
      for (int i = 1; i <= 5; i++) {
        files.add(R2FileItem(
          key: 'readme_$i.md',
          name: 'readme_$i.md',
          sizeMb: 0.001,
          lastModified: now.subtract(const Duration(days: 365)),
          publicUrl: 'https://cdn.isee.video/readme_$i.md',
        ));
      }
    }
    return files;
  }

  // ---------- Dashboard ----------
  DashboardData getDashboardData() {
    final now = DateTime.now();
    final totalContent = _contentList.length;
    final totalUsers = _users.length;
    final todayPlays = 12847 + _random.nextInt(3000);
    final monthlyRevenue = 482917.50 + _random.nextDouble() * 20000;

    final newUsers7 = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DailyDataPoint(
          date: date,
          value: (80 + _random.nextInt(40)).toDouble());
    });
    final plays30 = List.generate(30, (i) {
      final date = now.subtract(Duration(days: 29 - i));
      final weekend = date.weekday >= 6 ? 3000.0 : 0.0;
      return DailyDataPoint(
          date: date,
          value: 8000 + _random.nextDouble() * 4000 + weekend);
    });
    final revenue30 = List.generate(30, (i) {
      final date = now.subtract(Duration(days: 29 - i));
      return DailyDataPoint(
          date: date, value: 12000 + _random.nextDouble() * 6000);
    });

    final membershipDist = <MembershipTier, int>{
      MembershipTier.basic: _users.where((u) => u.membership.tier == MembershipTier.basic).length,
      MembershipTier.standard: _users.where((u) => u.membership.tier == MembershipTier.standard).length,
      MembershipTier.premium: _users.where((u) => u.membership.tier == MembershipTier.premium).length,
    };

    final topContent = _contentList
        .take(10)
        .map((v) => TopContentItem(
              videoId: v.id,
              title: v.title,
              posterUrl: v.posterUrl,
              playCount: 1000 + _random.nextInt(20000),
              watchMinutes: 5000 + _random.nextInt(50000),
              completionRate: 0.4 + _random.nextDouble() * 0.55,
            ))
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final recentActivity = [
      RecentActivityItem(
        id: 'act_001',
        type: 'content',
        description: '发布了新内容《星际穿越 4K 修复版》',
        time: now.subtract(const Duration(minutes: 12)),
        actorName: '超级管理员',
      ),
      RecentActivityItem(
        id: 'act_002',
        type: 'upload',
        description: '上传队列：深蓝海洋 S01E05 R2 上传进度 42%',
        time: now.subtract(const Duration(minutes: 30)),
        actorName: '内容编辑-小王',
      ),
      RecentActivityItem(
        id: 'act_003',
        type: 'user',
        description: '用户 user_003 从标准版升级为高级版',
        time: now.subtract(const Duration(hours: 2)),
      ),
      RecentActivityItem(
        id: 'act_004',
        type: 'system',
        description: '夜间定时拉取任务 mux_r2_nightly_pull 成功执行（12 项任务）',
        time: now.subtract(const Duration(hours: 6)),
        actorName: 'System',
      ),
      RecentActivityItem(
        id: 'act_005',
        type: 'content',
        description: '调整 Top 10 榜单：《暗影猎手》升至第 2 位',
        time: now.subtract(const Duration(hours: 9)),
        actorName: '内容编辑-小王',
      ),
      RecentActivityItem(
        id: 'act_006',
        type: 'user',
        description: '用户 user_047 账号因异常登录被自动冻结',
        time: now.subtract(const Duration(hours: 14)),
        actorName: 'System',
      ),
      RecentActivityItem(
        id: 'act_007',
        type: 'subscription',
        description: '本月会员收入 ¥${monthlyRevenue.toStringAsFixed(2)}，环比 +${(8 + _random.nextDouble() * 5).toStringAsFixed(1)}%',
        time: now.subtract(const Duration(days: 1)),
      ),
    ];

    return DashboardData(
      overview: DashboardOverviewStats(
        totalContent: totalContent,
        totalContentTrend: const TrendData(
          value: 12,
          direction: TrendDirection.up,
          changePercent: 12.4,
        ),
        totalUsers: totalUsers,
        totalUsersTrend: TrendData(
          value: 142,
          direction: TrendDirection.up,
          changePercent: 8.7 + _random.nextDouble() * 2,
        ),
        todayPlays: todayPlays,
        todayPlaysTrend: TrendData(
          value: 1830,
          direction:
              _random.nextBool() ? TrendDirection.up : TrendDirection.down,
          changePercent: 3.2 + _random.nextDouble() * 4,
        ),
        monthlyRevenue: monthlyRevenue,
        monthlyRevenueTrend: TrendData(
          value: monthlyRevenue * 0.11,
          direction: TrendDirection.up,
          changePercent: 11.2,
        ),
        activeUsersToday: 3421 + _random.nextInt(600),
        transcodingTasks:
            _uploadTasks.where((t) => t.stage == UploadStage.transcoding).length,
        pendingUploads:
            _uploadTasks.where((t) => !t.stage.isCompleted && !t.stage.isFailed).length,
      ),
      charts: DashboardCharts(
        newUsersLast7Days: newUsers7,
        playsLast30Days: plays30,
        revenueLast30Days: revenue30,
        membershipDistribution: membershipDist,
      ),
      topContentThisWeek: topContent,
      recentActivity: recentActivity,
    );
  }

  // ---------- Analytics ----------
  AnalyticsData getAnalyticsData() {
    final now = DateTime.now();
    final contentList = getAllContent();
    final categoriesList = MockData.categories.where((c) =>
        c.id.startsWith('cat_') &&
        !['cat_trending', 'cat_new', 'cat_top10'].contains(c.id)).toList();
    final catNames = categoriesList.map((c) => c.name).toList();

    // Top content
    final topContent = contentList
        .take(10)
        .map((v) => TopContentItem(
              videoId: v.id,
              title: v.title,
              posterUrl: v.posterUrl,
              playCount: 1000 + _random.nextInt(20000),
              watchMinutes: 5000 + _random.nextInt(50000),
              completionRate: 0.4 + _random.nextDouble() * 0.55,
            ))
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    // Category plays 30d
    final categoryPlays30d = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      final map = <String, double>{};
      for (final c in catNames) {
        map[c] = 500 + _random.nextDouble() * 4500;
      }
      return CategoryPlaysPoint(date: d, byCategory: map);
    });

    // New users 30d
    final newUsers30d = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return DailyDataPoint(
          date: d, value: (60 + _random.nextInt(80)).toDouble());
    });

    // 7-day retention
    final retention7d = const [
      RetentionDayPoint(day: 1, rate: 0.85),
      RetentionDayPoint(day: 2, rate: 0.68),
      RetentionDayPoint(day: 3, rate: 0.54),
      RetentionDayPoint(day: 4, rate: 0.42),
      RetentionDayPoint(day: 5, rate: 0.34),
      RetentionDayPoint(day: 6, rate: 0.28),
      RetentionDayPoint(day: 7, rate: 0.22),
    ];

    // Conversion funnel
    final conversionFunnel = const [
      FunnelStage(label: '注册用户', value: 10000),
      FunnelStage(label: '首次观看', value: 6800),
      FunnelStage(label: '订阅会员', value: 2400),
      FunnelStage(label: '成功续费', value: 1560),
    ];

    // Revenue 30d
    final revenue30d = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return DailyDataPoint(
          date: d, value: 10000 + _random.nextDouble() * 8000);
    });

    // Plan distribution
    final planDist = <MembershipTier, int>{
      MembershipTier.basic: _users.where((u) => u.membership.tier == MembershipTier.basic).length,
      MembershipTier.standard: _users.where((u) => u.membership.tier == MembershipTier.standard).length,
      MembershipTier.premium: _users.where((u) => u.membership.tier == MembershipTier.premium).length,
    };

    // ARPU 30d trend
    final arpuTrend = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return DailyDataPoint(date: d, value: 35 + _random.nextDouble() * 15);
    });

    // Avg watch minutes daily (30d)
    final avgWatchMinutesDaily = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return DailyDataPoint(
          date: d, value: 55 + _random.nextDouble() * 45);
    });

    // Device distribution
    final deviceDist = <String, int>{
      'Web / PC': 3420,
      'iOS': 2890,
      'Android': 3120,
      'Smart TV': 1180,
      'Tablet': 640,
    };

    // 24h distribution
    final hourDistribution24h = List.generate(24, (h) {
      double base;
      if (h >= 0 && h < 6) {
        base = 50 + _random.nextDouble() * 100;
      } else if (h >= 6 && h < 12) {
        base = 200 + _random.nextDouble() * 300;
      } else if (h >= 12 && h < 18) {
        base = 400 + _random.nextDouble() * 400;
      } else {
        base = 800 + _random.nextDouble() * 600;
      }
      return HourDistributionPoint(hour: h, value: base);
    });

    return AnalyticsData(
      topContentList: topContent,
      categoryPlays30d: categoryPlays30d,
      newUsers30d: newUsers30d,
      retention7d: retention7d,
      conversionFunnel: conversionFunnel,
      revenue30d: revenue30d,
      planDistribution: planDist,
      arpuTrend: arpuTrend,
      avgWatchMinutesDaily: avgWatchMinutesDaily,
      deviceDistribution: deviceDist,
      hourDistribution24h: hourDistribution24h,
    );
  }

  // ---------- System config ----------
  SystemConfig getSystemConfig() {
    return SystemConfig(
      site: const SiteConfig(
        siteName: 'iSEE',
        siteDescription: '无国内云服务的流媒体视频订阅平台',
        logoUrl: 'https://cdn.isee.video/logo.png',
        faviconUrl: 'https://cdn.isee.video/favicon.png',
        announcement: '🎉 新片《星际穿越 4K 修复版》已上线，高级版会员抢先观看！',
        supportEmail: 'support@isee.video',
      ),
      mux: const MuxConfig(
        tokenId: 'mux_token_id_prod_abcdef1234567890',
        tokenSecret: 'mux_token_secret_prod_xyz',
        environment: 'production',
        enable2160pTranscode: true,
        defaultMaxResolutionTier: '2160p',
        defaultVideoQuality: 'basic',
      ),
      r2: const R2Config(
        accountId: 'r2_account_id_1234567890abcdef',
        accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
        secretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        bucketName: 'isee-video-prod',
        publicBaseUrl: 'https://cdn.isee.video',
        uploadFolder: 'videos',
        region: 'auto',
      ),
      playback: const PlaybackConfig(),
      lastUpdatedAt: DateTime.now().subtract(const Duration(days: 3)),
      lastUpdatedBy: 'admin_001',
    );
  }
}

extension _UploadStageProgressCopy on UploadStageProgress {
  UploadStageProgress copyWithPercent(int percent, UploadStage stage) {
    return UploadStageProgress(
      stage: stage,
      percent: percent,
      speedMbps: speedMbps,
      transferredMb: transferredMb,
      totalMb: totalMb,
      etaSeconds: etaSeconds,
    );
  }
}
