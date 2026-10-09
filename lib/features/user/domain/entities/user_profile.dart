import '../../../../core/models/video_quality.dart';

enum MembershipTier { basic, standard, premium }

enum UserStatus { active, frozen, expired }

extension UserStatusExtension on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return '正常';
      case UserStatus.frozen:
        return '已冻结';
      case UserStatus.expired:
        return '已过期';
    }
  }
}

extension MembershipTierExtension on MembershipTier {
  String get label {
    switch (this) {
      case MembershipTier.basic:
        return '基础版';
      case MembershipTier.standard:
        return '标准版';
      case MembershipTier.premium:
        return '高级版';
    }
  }

  String get shortLabel {
    switch (this) {
      case MembershipTier.basic:
        return 'Basic';
      case MembershipTier.standard:
        return 'Standard';
      case MembershipTier.premium:
        return 'Premium';
    }
  }
}

class MembershipPlan {
  final String id;
  final MembershipTier tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int maxDevices;
  final int maxDownloads;
  final VideoQuality maxQuality;
  final List<String> features;
  final bool isActive;
  final DateTime? updatedAt;

  const MembershipPlan({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxDevices,
    required this.maxDownloads,
    required this.maxQuality,
    required this.features,
    this.isActive = true,
    this.updatedAt,
  });

  MembershipPlan copyWith({
    String? id,
    MembershipTier? tier,
    String? name,
    String? description,
    double? monthlyPrice,
    double? yearlyPrice,
    int? maxDevices,
    int? maxDownloads,
    VideoQuality? maxQuality,
    List<String>? features,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return MembershipPlan(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      maxDevices: maxDevices ?? this.maxDevices,
      maxDownloads: maxDownloads ?? this.maxDownloads,
      maxQuality: maxQuality ?? this.maxQuality,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserMembership {
  final MembershipTier tier;
  final MembershipPlan plan;
  final DateTime startDate;
  final DateTime expireDate;
  final bool isActive;
  final bool isAutoRenew;
  final String? paymentMethod;
  final List<SubscriptionEvent> history;

  const UserMembership({
    required this.tier,
    required this.plan,
    required this.startDate,
    required this.expireDate,
    this.isActive = true,
    this.isAutoRenew = true,
    this.paymentMethod,
    this.history = const [],
  });

  int get remainingDays {
    final now = DateTime.now();
    return expireDate.difference(now).inDays;
  }

  UserMembership copyWith({
    MembershipTier? tier,
    MembershipPlan? plan,
    DateTime? startDate,
    DateTime? expireDate,
    bool? isActive,
    bool? isAutoRenew,
    String? paymentMethod,
    List<SubscriptionEvent>? history,
  }) {
    return UserMembership(
      tier: tier ?? this.tier,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      expireDate: expireDate ?? this.expireDate,
      isActive: isActive ?? this.isActive,
      isAutoRenew: isAutoRenew ?? this.isAutoRenew,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      history: history ?? this.history,
    );
  }
}

class SubscriptionEvent {
  final String id;
  final String type;
  final DateTime date;
  final String description;
  final double? amount;

  const SubscriptionEvent({
    required this.id,
    required this.type,
    required this.date,
    required this.description,
    this.amount,
  });
}

class WatchHistoryItem {
  final String videoId;
  final String? episodeId;
  final String videoTitle;
  final DateTime watchedAt;
  final double progress;
  final int watchMinutes;

  const WatchHistoryItem({
    required this.videoId,
    this.episodeId,
    required this.videoTitle,
    required this.watchedAt,
    required this.progress,
    required this.watchMinutes,
  });
}

class UserProfile {
  final String id;
  final String email;
  final String phone;
  final String displayName;
  final String avatarUrl;
  final String language;
  final VideoQuality preferredQuality;
  final bool autoplayNext;
  final bool autoplayTrailers;
  final List<String> myListIds;
  final Map<String, double> watchProgress;
  final UserMembership membership;
  final DateTime registeredAt;
  final DateTime? lastLoginAt;
  final UserStatus status;
  final int totalWatchMinutes;
  final int loginCount;
  final String? region;
  final List<WatchHistoryItem> recentWatchHistory;

  UserProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.avatarUrl,
    this.language = 'zh-CN',
    this.preferredQuality = VideoQuality.q1080p,
    this.autoplayNext = true,
    this.autoplayTrailers = true,
    this.myListIds = const [],
    this.watchProgress = const {},
    required this.membership,
    DateTime? registeredAt,
    this.lastLoginAt,
    this.status = UserStatus.active,
    this.totalWatchMinutes = 0,
    this.loginCount = 0,
    this.region,
    this.recentWatchHistory = const [],
  }) : registeredAt = registeredAt ?? DateTime.now();

  UserProfile copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? avatarUrl,
    String? language,
    VideoQuality? preferredQuality,
    bool? autoplayNext,
    bool? autoplayTrailers,
    List<String>? myListIds,
    Map<String, double>? watchProgress,
    UserMembership? membership,
    DateTime? registeredAt,
    DateTime? lastLoginAt,
    UserStatus? status,
    int? totalWatchMinutes,
    int? loginCount,
    String? region,
    List<WatchHistoryItem>? recentWatchHistory,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      autoplayNext: autoplayNext ?? this.autoplayNext,
      autoplayTrailers: autoplayTrailers ?? this.autoplayTrailers,
      myListIds: myListIds ?? this.myListIds,
      watchProgress: watchProgress ?? this.watchProgress,
      membership: membership ?? this.membership,
      registeredAt: registeredAt ?? this.registeredAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      status: status ?? this.status,
      totalWatchMinutes: totalWatchMinutes ?? this.totalWatchMinutes,
      loginCount: loginCount ?? this.loginCount,
      region: region ?? this.region,
      recentWatchHistory: recentWatchHistory ?? this.recentWatchHistory,
    );
  }
}
