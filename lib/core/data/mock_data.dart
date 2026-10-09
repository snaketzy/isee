import '../models/video_quality.dart';
import '../../features/content/domain/entities/video_content.dart';
import '../../features/user/domain/entities/user_profile.dart';

class MockData {
  static String _img(String id, {int w = 400, int h = 600}) =>
      'https://picsum.photos/seed/$id/$w/$h';

  static String _bd(String id) => 'https://picsum.photos/seed/${id}bd/1600/900';

  static String _thumb(String id) => 'https://picsum.photos/seed/${id}th/400/225';

  static const String placeholderVideo =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  static const String muxTest4Hls =
      'https://stream.mux.com/XceDtWCR2F01InyWrAcI00JeLtWCDPcOjN4g01im00Y0100FQ.m3u8';

  static Map<VideoQuality, String> get _videoUrls => {
        VideoQuality.q360p: placeholderVideo,
        VideoQuality.q480p: placeholderVideo,
        VideoQuality.q720p: placeholderVideo,
        VideoQuality.q1080p: placeholderVideo,
      };

  static Map<VideoQuality, String> get _videoUrlsMuxTest4 => {
        VideoQuality.q360p: muxTest4Hls,
        VideoQuality.q480p: muxTest4Hls,
        VideoQuality.q720p: muxTest4Hls,
        VideoQuality.q1080p: muxTest4Hls,
      };

  static List<Episode> _generateEpisodes(String videoId, int season, int count) {
    return List.generate(count, (i) {
      return Episode(
        id: '${videoId}_s${season}_e${i + 1}',
        seasonNumber: season,
        episodeNumber: i + 1,
        title: [
          '神秘来客',
          '暗流涌动',
          '真相浮现',
          '迷雾重重',
          '命运抉择',
          '最后一刻',
          '风暴中心',
          '绝地反击',
          '终极对决',
          '新的开始',
        ][i % 10],
        description:
            '这是第 ${i + 1} 集的精彩内容。故事继续发展，主角们面临新的挑战和抉择。随着剧情推进，更多秘密被揭开，人物关系也变得更加错综复杂。',
        duration: Duration(minutes: 45 + (i % 15)),
        thumbnailUrl: _thumb('${videoId}_s${season}_e${i + 1}'),
        videoUrl: placeholderVideo,
        videoUrls: _videoUrls,
      );
    });
  }

  static List<Season> _generateSeasons(String videoId, int seasonCount) {
    return List.generate(seasonCount, (s) {
      return Season(
        seasonNumber: s + 1,
        title: '第 ${s + 1} 季',
        description: '全新一季的故事即将展开，更多精彩内容等你发现。',
        episodes: _generateEpisodes(videoId, s + 1, 10),
      );
    });
  }

  static final List<VideoContent> _allVideos = [
    VideoContent(
      id: 'v001',
      title: '星际迷航：新纪元',
      originalTitle: 'Star Trek: New Era',
      description:
          '2380年，星际联邦迎来和平年代。企业号NCC-1701-E在深空探索中发现了一个未知的虫洞，它连接着银河系的另一端。然而，穿越虫洞后，船员们发现了一个古老文明留下的威胁——一个被遗忘的超级种族，他们的回归将改变整个星系的命运。',
      type: VideoType.series,
      releaseYear: 2024,
      rating: 9.2,
      maturityRating: 'TV-14',
      genres: const ['科幻', '冒险', '剧情'],
      cast: const ['李明远', '张雪琪', '陈宇航', 'Sarah Chen', 'Mike Johnson'],
      directors: const ['王宇宙'],
      posterUrl: _img('v001'),
      backdropUrl: _bd('v001'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v001', 3),
      totalEpisodes: 30,
      addedAt: DateTime.now().subtract(const Duration(days: 7)),
      isTrending: true,
      isNewRelease: true,
      isTopTen: true,
      topTenRank: 1,
    ),
    VideoContent(
      id: 'v002',
      title: '暗影猎手',
      originalTitle: 'Shadow Hunter',
      description:
          '在一个被黑暗笼罩的城市里，一名退役特种兵陈默成为了地下世界中唯一的执法者。当一连串离奇的连环杀人案发生时，他必须面对自己过去的阴影，与一个神秘的女黑客联手，揭开一个涉及整个城市高层的惊天阴谋。',
      type: VideoType.movie,
      releaseYear: 2024,
      duration: const Duration(minutes: 135),
      rating: 8.7,
      maturityRating: 'TV-MA',
      genres: const ['动作', '犯罪', '惊悚'],
      cast: const ['王强', '林雨', '吴天', '刘芳'],
      directors: const ['李刚'],
      posterUrl: _img('v002'),
      backdropUrl: _bd('v002'),
      trailerUrl: muxTest4Hls,
      mainVideoUrl: muxTest4Hls,
      mainVideoUrls: _videoUrlsMuxTest4,
      addedAt: DateTime.now().subtract(const Duration(days: 3)),
      isTrending: true,
      isNewRelease: true,
      isTopTen: true,
      topTenRank: 2,
    ),
    VideoContent(
      id: 'v003',
      title: '爱在东京',
      originalTitle: 'Love in Tokyo',
      description:
          '上海女孩苏小曼因工作调动来到东京，在樱花盛开的季节里，她邂逅了在日式甜点店工作的日本青年山下健一。两人从误会到相识，从相知到相爱，跨越文化差异，谱写了一段温暖人心的跨国恋曲。',
      type: VideoType.movie,
      releaseYear: 2023,
      duration: const Duration(minutes: 118),
      rating: 8.1,
      maturityRating: 'TV-PG',
      genres: const ['爱情', '剧情', '喜剧'],
      cast: const ['苏小曼', '山下健一', '周小萌', '佐藤美咲'],
      directors: const ['陈爱华'],
      posterUrl: _img('v003'),
      backdropUrl: _bd('v003'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      addedAt: DateTime.now().subtract(const Duration(days: 30)),
      isTrending: true,
    ),
    VideoContent(
      id: 'v004',
      title: '王朝风云',
      originalTitle: 'Dynasty Storm',
      description:
          '大唐盛世，暗流涌动。皇太子李弘与诸王之间的夺嫡之争愈演愈烈，女主沈明月以罪臣之女的身份入宫，凭借智慧和隐忍，在波诡云谲的深宫中一步步走上权力的巅峰，影响了整个王朝的走向。',
      type: VideoType.series,
      releaseYear: 2024,
      rating: 9.0,
      maturityRating: 'TV-14',
      genres: const ['古装', '剧情', '历史'],
      cast: const ['赵雅琴', '李明浩', '周子墨', '徐文轩'],
      directors: const ['郑小刚'],
      posterUrl: _img('v004'),
      backdropUrl: _bd('v004'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v004', 2),
      totalEpisodes: 60,
      addedAt: DateTime.now().subtract(const Duration(days: 14)),
      isTrending: true,
      isTopTen: true,
      topTenRank: 3,
    ),
    VideoContent(
      id: 'v005',
      title: '深渊回响',
      originalTitle: 'Echoes of Abyss',
      description:
          '深海科研团队在马里亚纳海沟底部发现了一种前所未有的生物信号。随着深入调查，他们意识到这不是自然生命的秘密，而是一个来自人类史前文明的警告——一个沉睡了数百万年的秘密即将苏醒。',
      type: VideoType.series,
      releaseYear: 2024,
      rating: 8.8,
      maturityRating: 'TV-14',
      genres: const ['科幻', '悬疑', '恐怖'],
      cast: const ['陈海波', '林深', 'Dr. Williams', '刘洋'],
      directors: const ['张深'],
      posterUrl: _img('v005'),
      backdropUrl: _bd('v005'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v005', 1),
      totalEpisodes: 12,
      addedAt: DateTime.now().subtract(const Duration(days: 5)),
      isNewRelease: true,
    ),
    VideoContent(
      id: 'v006',
      title: '笑闹厨房',
      originalTitle: 'Funny Kitchen',
      description:
          '米其林三星主厨江俊浩因一场意外失去味觉，落魄回到家乡小镇继承父亲的小饭馆。他决定重振家业的过程中，与从小一起长大的活泼女孩田小厨一起，用一道道充满温情的家常菜，唤醒了小镇居民的味蕾和记忆。',
      type: VideoType.tvShow,
      releaseYear: 2024,
      rating: 8.4,
      maturityRating: 'TV-PG',
      genres: const ['喜剧', '美食', '治愈'],
      cast: const ['江俊浩', '田小厨', '老王头', '赵美食'],
      directors: const ['陈晓厨'],
      posterUrl: _img('v006'),
      backdropUrl: _bd('v006'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v006', 1),
      totalEpisodes: 24,
      addedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    VideoContent(
      id: 'v007',
      title: '荒野求生：非洲大草原',
      originalTitle: 'Wild Survival: African Savannah',
      description:
          '全球顶级探险家贝尔·格里尔斯带领观众深入非洲塞伦盖蒂大草原，面对狮子、鬣狗、非洲野犬等凶猛野生动物，在极端环境下展示最原始的生存技巧和智慧。',
      type: VideoType.documentary,
      releaseYear: 2024,
      rating: 8.9,
      maturityRating: 'TV-PG',
      genres: const ['纪录片', '冒险', '自然'],
      cast: const ['贝尔·格里尔斯'],
      directors: const ['国家地理频道'],
      posterUrl: _img('v007'),
      backdropUrl: _bd('v007'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v007', 1),
      totalEpisodes: 8,
      addedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    VideoContent(
      id: 'v008',
      title: '机械心脏',
      originalTitle: 'Mechanical Heart',
      description:
          '未来2099年，人工智能已经完全融入人类生活。天才工程师林薇儿在经历一场车祸后，用自己发明的机械心脏保住了生命，却发现自己开始逐渐失去人类的情感。她必须在完全变成机器之前，找到那个让她重新为人的答案。',
      type: VideoType.movie,
      releaseYear: 2024,
      duration: const Duration(minutes: 142),
      rating: 8.6,
      maturityRating: 'TV-14',
      genres: const ['科幻', '剧情'],
      cast: const ['林薇儿', '陈博士', '陈未来', 'Ava AI'],
      directors: const ['刘未来'],
      posterUrl: _img('v008'),
      backdropUrl: _bd('v008'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      addedAt: DateTime.now().subtract(const Duration(days: 2)),
      isNewRelease: true,
      isTopTen: true,
      topTenRank: 4,
    ),
    VideoContent(
      id: 'v009',
      title: '犯罪心理画像师',
      originalTitle: 'Criminal Profiler',
      description:
          '犯罪心理学教授方敏仪博士，能够通过犯罪现场还原凶手的心理画像。她与刑警队长赵雷搭档，破获了一系列匪夷所思的连环案件。每个案件的背后，都隐藏着令人唏嘘的人性故事，在一次次与高智商罪犯的终极较量中，方敏仪也逐渐揭开了自己身世的秘密。',
      type: VideoType.series,
      releaseYear: 2023,
      rating: 9.1,
      maturityRating: 'TV-MA',
      genres: const ['犯罪', '悬疑', '剧情'],
      cast: const ['方敏仪', '赵雷', '李法医', '周分析'],
      directors: const ['王心理'],
      posterUrl: _img('v009'),
      backdropUrl: _bd('v009'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v009', 4),
      totalEpisodes: 48,
      addedAt: DateTime.now().subtract(const Duration(days: 60)),
      isTopTen: true,
      topTenRank: 5,
    ),
    VideoContent(
      id: 'v010',
      title: '山河故人',
      originalTitle: 'Old Friends of Mountains and Rivers',
      description:
          '四位年过七旬的老兵在战友葬礼上重逢，为了完成已故战友的遗愿，他们决定重走五十多年前的参军之路。旅途中，他们回忆青春岁月，面对生老病死，用一段段感人至深的旅程，诠释了什么是真正的友情与坚守。',
      type: VideoType.movie,
      releaseYear: 2023,
      duration: const Duration(minutes: 128),
      rating: 9.3,
      maturityRating: 'TV-PG',
      genres: const ['剧情', '历史'],
      cast: const ['张国立级', '李宝田', '王铁林', '陈老戏骨'],
      directors: const ['张艺谋风'],
      posterUrl: _img('v010'),
      backdropUrl: _bd('v010'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      addedAt: DateTime.now().subtract(const Duration(days: 90)),
      isTopTen: true,
      topTenRank: 6,
    ),
    VideoContent(
      id: 'v011',
      title: '电竞之王',
      originalTitle: 'King of Esports',
      description:
          '曾经的电竞天才少年凌云，因一场比赛失利退役五年后重返赛场。他带领一支由问题少年组成的新战队，一路披荆斩棘，从城市赛、季后赛，最终站上了世界赛的舞台，重新证明自己。',
      type: VideoType.series,
      releaseYear: 2024,
      rating: 8.3,
      maturityRating: 'TV-14',
      genres: const ['青春', '电竞', '励志'],
      cast: const ['凌云', '少年ADC', '辅助小妹', '教练老帅'],
      directors: const ['电竞王'],
      posterUrl: _img('v011'),
      backdropUrl: _bd('v011'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v011', 1),
      totalEpisodes: 36,
      addedAt: DateTime.now().subtract(const Duration(days: 12)),
      isTopTen: true,
      topTenRank: 7,
    ),
    VideoContent(
      id: 'v012',
      title: '灵异档案馆',
      originalTitle: 'Paranormal Archives',
      description:
          '一个专门处理常规案件的档案馆中，存放着一件件无法解释的诡异档案。每个档案都记录着一个真实发生过的故事——鬼影、降头、蛊毒、前世今生……这一切的背后，究竟是人心作祟，还是真的有另一个世界？',
      type: VideoType.series,
      releaseYear: 2024,
      rating: 8.5,
      maturityRating: 'TV-MA',
      genres: const ['恐怖', '悬疑', '灵异'],
      cast: const ['馆长', '小档案员', '阴阳眼', '老道士'],
      directors: const ['灵异导'],
      posterUrl: _img('v012'),
      backdropUrl: _bd('v012'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v012', 2),
      totalEpisodes: 20,
      addedAt: DateTime.now().subtract(const Duration(days: 25)),
      isTopTen: true,
      topTenRank: 8,
    ),
    VideoContent(
      id: 'v013',
      title: '硅谷创业者',
      originalTitle: 'Silicon Valley Startup',
      description:
          '三位华人工程师怀揣梦想在硅谷创业，从车库里的一个小想法开始，经历融资、团队扩张、产品失败、绝境重生，真实还原了科技创业的热血与残酷，记录了一代华人在异乡拼搏的奋斗史诗。',
      type: VideoType.documentary,
      releaseYear: 2024,
      rating: 9.0,
      maturityRating: 'TV-14',
      genres: const ['纪录片', '科技', '传记'],
      cast: const ['真实人物'],
      directors: const ['纪实导演'],
      posterUrl: _img('v013'),
      backdropUrl: _bd('v013'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v013', 1),
      totalEpisodes: 6,
      addedAt: DateTime.now().subtract(const Duration(days: 45)),
      isTopTen: true,
      topTenRank: 9,
    ),
    VideoContent(
      id: 'v014',
      title: '末日列车',
      originalTitle: 'Doomsday Train',
      description:
          '全球爆发未知病毒后，一辆永不停歇的列车成为人类最后的避难所。列车上分为上中下三等车厢，资源分配极度不公，末节车厢的人们在领袖的带领下，发起了一场改变命运的暴动。',
      type: VideoType.movie,
      releaseYear: 2024,
      duration: const Duration(minutes: 155),
      rating: 8.8,
      maturityRating: 'TV-MA',
      genres: const ['动作', '科幻', '惊悚'],
      cast: const ['Chris Evans', '宋康昊', '蒂尔达·斯文顿'],
      directors: const ['奉俊昊风格'],
      posterUrl: _img('v014'),
      backdropUrl: _bd('v014'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      addedAt: DateTime.now().subtract(const Duration(days: 40)),
      isTopTen: true,
      topTenRank: 10,
    ),
    VideoContent(
      id: 'v015',
      title: '南方的女儿',
      originalTitle: 'Southern Daughter',
      description:
          '90年代的江南小镇，女孩苏晓鱼从小被领养。她凭借坚韧的性格和过人的智慧，在重男轻女的环境中一步步成长，最终走出小镇考上大学，后来又回乡创业带动全村致富，成为了自己命运的主人。',
      type: VideoType.series,
      releaseYear: 2023,
      rating: 8.9,
      maturityRating: 'TV-PG',
      genres: const ['剧情', '年代', '女性'],
      cast: const ['苏晓鱼', '养母', '村长老爹', '青梅竹马'],
      directors: const ['年代剧导'],
      posterUrl: _img('v015'),
      backdropUrl: _bd('v015'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v015', 1),
      totalEpisodes: 40,
      addedAt: DateTime.now().subtract(const Duration(days: 75)),
    ),
    VideoContent(
      id: 'v016',
      title: '宇宙尽头的餐厅',
      originalTitle: 'Restaurant at the End of Universe',
      description:
          '每到深夜零点，一家只存在于时空裂缝中的神秘餐厅会准时开门。每位客人都带着一个心结而来，主厨会根据他们的记忆，做出一道专属的料理。每一道菜的背后，都藏着一个笑中带泪的故事。',
      type: VideoType.tvShow,
      releaseYear: 2024,
      rating: 9.0,
      maturityRating: 'TV-14',
      genres: const ['奇幻', '治愈', '美食'],
      cast: const ['深夜主厨', '时间侍者', '各色食客'],
      directors: const ['深夜食堂'],
      posterUrl: _img('v016'),
      backdropUrl: _bd('v016'),
      trailerUrl: placeholderVideo,
      mainVideoUrl: placeholderVideo,
      mainVideoUrls: _videoUrls,
      seasons: _generateSeasons('v016', 1),
      totalEpisodes: 12,
      addedAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];

  static final List<VideoCategory> categories = [
    VideoCategory(
      id: 'cat_trending',
      name: '🔥 今日热门',
      videos: _allVideos.where((v) => v.isTrending || v.isTopTen).toList()
        ..sort((a, b) => (b.topTenRank ?? 99).compareTo(a.topTenRank ?? 99)),
    ),
    VideoCategory(
      id: 'cat_new',
      name: '✨ 新上线',
      videos: _allVideos.where((v) => v.isNewRelease).toList(),
    ),
    VideoCategory(
      id: 'cat_top10',
      name: '🏆 本周 Top 10',
      videos: _allVideos.where((v) => v.isTopTen).toList()
        ..sort((a, b) => (a.topTenRank ?? 99).compareTo(b.topTenRank ?? 99)),
    ),
    VideoCategory(
      id: 'cat_scifi',
      name: '🚀 科幻精选',
      videos: _allVideos.where((v) => v.genres.contains('科幻')).toList(),
    ),
    VideoCategory(
      id: 'cat_action',
      name: '💥 动作大片',
      videos: _allVideos.where((v) => v.genres.contains('动作') || v.genres.contains('犯罪')).toList(),
    ),
    VideoCategory(
      id: 'cat_romance',
      name: '💕 爱情故事',
      videos: _allVideos.where((v) => v.genres.contains('爱情')).toList(),
    ),
    VideoCategory(
      id: 'cat_series',
      name: '📺 热门剧集',
      videos: _allVideos.where((v) => v.isSeries).toList(),
    ),
    VideoCategory(
      id: 'cat_movie',
      name: '🎬 院线电影',
      videos: _allVideos.where((v) => v.type == VideoType.movie).toList(),
    ),
    VideoCategory(
      id: 'cat_domestic',
      name: '🇨🇳 国产精品',
      videos: _allVideos.sublist(0, 10),
    ),
    VideoCategory(
      id: 'cat_docu',
      name: '🌍 纪录片',
      videos: _allVideos.where((v) => v.type == VideoType.documentary).toList(),
    ),
  ];

  static final List<MembershipPlan> membershipPlans = [
    MembershipPlan(
      id: 'plan_basic',
      tier: MembershipTier.basic,
      name: '基础版',
      description: '适合个人轻度观看，性价比之选',
      monthlyPrice: 29.0,
      yearlyPrice: 288.0,
      maxDevices: 1,
      maxDownloads: 1,
      maxQuality: VideoQuality.q720p,
      features: const [
        '720p HD 高清画质',
        '1台设备同时观看',
        '支持1台设备下载离线',
        '无广告观看',
        '随时取消订阅',
      ],
    ),
    MembershipPlan(
      id: 'plan_standard',
      tier: MembershipTier.standard,
      name: '标准版',
      description: '家庭首选，全高清观影体验',
      monthlyPrice: 49.0,
      yearlyPrice: 488.0,
      maxDevices: 2,
      maxDownloads: 2,
      maxQuality: VideoQuality.q1080p,
      features: const [
        '1080p Full HD 全高清画质',
        '2台设备同时观看',
        '支持2台设备下载离线',
        '无广告观看',
        '随时取消订阅',
        '独家首播内容',
      ],
    ),
    MembershipPlan(
      id: 'plan_premium',
      tier: MembershipTier.premium,
      name: '高级版',
      description: '极致体验，4K超清全家共享',
      monthlyPrice: 79.0,
      yearlyPrice: 788.0,
      maxDevices: 4,
      maxDownloads: 4,
      maxQuality: VideoQuality.q4k,
      features: const [
        '4K Ultra HD + HDR 超清画质',
        '4台设备同时观看',
        '支持4台设备下载离线',
        '无广告观看',
        '随时取消订阅',
        '独家首播内容',
        '杜比全景声',
        '优先观看新片',
      ],
    ),
  ];

  static UserProfile buildMockUser() {
    final premiumPlan = membershipPlans[2];
    return UserProfile(
      id: 'user_001',
      email: 'test_user@isee.video',
      phone: '+86 138****8888',
      displayName: '测试会员',
      avatarUrl: _img('avatar', w: 200, h: 200),
      language: 'zh-CN',
      preferredQuality: VideoQuality.q1080p,
      autoplayNext: true,
      autoplayTrailers: true,
      myListIds: const ['v001', 'v004', 'v009', 'v010', 'v016'],
      watchProgress: const {
        'v001_s1_e1': 0.75,
        'v001_s1_e2': 0.30,
        'v002': 0.55,
        'v004_s1_e1': 1.0,
        'v004_s1_e2': 0.85,
      },
      membership: UserMembership(
        tier: MembershipTier.premium,
        plan: premiumPlan,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        expireDate: DateTime.now().add(const Duration(days: 320)),
        isActive: true,
        isAutoRenew: true,
        paymentMethod: 'Stripe •••• 4242',
      ),
      registeredAt: DateTime.now().subtract(const Duration(days: 120)),
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: UserStatus.active,
      totalWatchMinutes: 28471,
      loginCount: 342,
      region: '上海',
    );
  }

  static VideoContent? getVideoById(String id) {
    for (final v in _allVideos) {
      if (v.id == id) return v;
    }
    return null;
  }

  static List<VideoContent> getAllVideos() => List.unmodifiable(_allVideos);

  static Episode? findEpisode(String videoId, int episodeIndex) {
    final video = getVideoById(videoId);
    if (video == null || video.seasons == null) return null;
    int counter = 0;
    for (final s in video.seasons!) {
      for (final e in s.episodes) {
        if (counter == episodeIndex) return e;
        counter++;
      }
    }
    return null;
  }

  static List<VideoContent> searchVideos(String query) {
    if (query.isEmpty) return const [];
    final q = query.toLowerCase();
    return _allVideos.where((v) {
      return v.title.toLowerCase().contains(q) ||
          v.originalTitle.toLowerCase().contains(q) ||
          v.description.toLowerCase().contains(q) ||
          v.genres.any((g) => g.toLowerCase().contains(q)) ||
          v.cast.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }

  static void updateMembershipPlans(List<MembershipPlan> newPlans) {
    membershipPlans
      ..clear()
      ..addAll(newPlans);
  }

  static List<VideoCategory> get categoriesList =>
      List.unmodifiable(categories);
}
