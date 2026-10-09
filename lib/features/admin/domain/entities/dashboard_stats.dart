import '../../../user/domain/entities/user_profile.dart';

enum TrendDirection { up, down, flat }

class TrendData {
  final double value;
  final TrendDirection direction;
  final double changePercent;

  const TrendData({
    required this.value,
    required this.direction,
    required this.changePercent,
  });
}

class DashboardOverviewStats {
  final int totalContent;
  final TrendData totalContentTrend;
  final int totalUsers;
  final TrendData totalUsersTrend;
  final int todayPlays;
  final TrendData todayPlaysTrend;
  final double monthlyRevenue;
  final TrendData monthlyRevenueTrend;
  final int activeUsersToday;
  final int transcodingTasks;
  final int pendingUploads;

  const DashboardOverviewStats({
    required this.totalContent,
    required this.totalContentTrend,
    required this.totalUsers,
    required this.totalUsersTrend,
    required this.todayPlays,
    required this.todayPlaysTrend,
    required this.monthlyRevenue,
    required this.monthlyRevenueTrend,
    required this.activeUsersToday,
    required this.transcodingTasks,
    required this.pendingUploads,
  });
}

class DailyDataPoint {
  final DateTime date;
  final double value;

  const DailyDataPoint({
    required this.date,
    required this.value,
  });
}

class DashboardCharts {
  final List<DailyDataPoint> newUsersLast7Days;
  final List<DailyDataPoint> playsLast30Days;
  final List<DailyDataPoint> revenueLast30Days;
  final Map<MembershipTier, int> membershipDistribution;

  const DashboardCharts({
    required this.newUsersLast7Days,
    required this.playsLast30Days,
    required this.revenueLast30Days,
    required this.membershipDistribution,
  });
}

class TopContentItem {
  final String videoId;
  final String title;
  final String posterUrl;
  final int playCount;
  final int watchMinutes;
  final double completionRate;

  const TopContentItem({
    required this.videoId,
    required this.title,
    required this.posterUrl,
    required this.playCount,
    required this.watchMinutes,
    required this.completionRate,
  });
}

class RecentActivityItem {
  final String id;
  final String type;
  final String description;
  final DateTime time;
  final String? actorName;

  const RecentActivityItem({
    required this.id,
    required this.type,
    required this.description,
    required this.time,
    this.actorName,
  });
}

class DashboardData {
  final DashboardOverviewStats overview;
  final DashboardCharts charts;
  final List<TopContentItem> topContentThisWeek;
  final List<RecentActivityItem> recentActivity;

  const DashboardData({
    required this.overview,
    required this.charts,
    required this.topContentThisWeek,
    required this.recentActivity,
  });
}

// ============ Analytics 扩展数据 ============

class CategoryPlaysPoint {
  final DateTime date;
  final Map<String, double> byCategory;
  const CategoryPlaysPoint({required this.date, required this.byCategory});
}

class RetentionDayPoint {
  final int day;
  final double rate;
  const RetentionDayPoint({required this.day, required this.rate});
}

class FunnelStage {
  final String label;
  final double value;
  const FunnelStage({required this.label, required this.value});
}

class HourDistributionPoint {
  final int hour;
  final double value;
  const HourDistributionPoint({required this.hour, required this.value});
}

class AnalyticsData {
  // 内容表现
  final List<TopContentItem> topContentList;
  final List<CategoryPlaysPoint> categoryPlays30d;

  // 用户增长
  final List<DailyDataPoint> newUsers30d;
  final List<RetentionDayPoint> retention7d;
  final List<FunnelStage> conversionFunnel;

  // 收入
  final List<DailyDataPoint> revenue30d;
  final Map<MembershipTier, int> planDistribution;
  final List<DailyDataPoint> arpuTrend;

  // 观看行为
  final List<DailyDataPoint> avgWatchMinutesDaily;
  final Map<String, int> deviceDistribution;
  final List<HourDistributionPoint> hourDistribution24h;

  const AnalyticsData({
    required this.topContentList,
    required this.categoryPlays30d,
    required this.newUsers30d,
    required this.retention7d,
    required this.conversionFunnel,
    required this.revenue30d,
    required this.planDistribution,
    required this.arpuTrend,
    required this.avgWatchMinutesDaily,
    required this.deviceDistribution,
    required this.hourDistribution24h,
  });
}
