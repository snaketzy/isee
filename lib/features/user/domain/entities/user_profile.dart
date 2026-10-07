import '../../../../core/models/video_quality.dart';

enum MembershipTier { basic, standard, premium }

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
  });
}

class UserMembership {
  final MembershipTier tier;
  final MembershipPlan plan;
  final DateTime startDate;
  final DateTime expireDate;
  final bool isActive;
  final bool isAutoRenew;
  final String? paymentMethod;

  const UserMembership({
    required this.tier,
    required this.plan,
    required this.startDate,
    required this.expireDate,
    this.isActive = true,
    this.isAutoRenew = true,
    this.paymentMethod,
  });

  int get remainingDays {
    final now = DateTime.now();
    return expireDate.difference(now).inDays;
  }
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

  const UserProfile({
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
  });
}
