class SiteConfig {
  final String siteName;
  final String siteDescription;
  final String logoUrl;
  final String faviconUrl;
  final String? announcement;
  final String? supportEmail;
  final String defaultLanguage;
  final bool enableUserRegistration;
  final bool maintenanceMode;
  final String? maintenanceMessage;

  const SiteConfig({
    required this.siteName,
    required this.siteDescription,
    required this.logoUrl,
    required this.faviconUrl,
    this.announcement,
    this.supportEmail,
    this.defaultLanguage = 'zh-CN',
    this.enableUserRegistration = true,
    this.maintenanceMode = false,
    this.maintenanceMessage,
  });

  SiteConfig copyWith({
    String? siteName,
    String? siteDescription,
    String? logoUrl,
    String? faviconUrl,
    String? announcement,
    String? supportEmail,
    String? defaultLanguage,
    bool? enableUserRegistration,
    bool? maintenanceMode,
    String? maintenanceMessage,
  }) {
    return SiteConfig(
      siteName: siteName ?? this.siteName,
      siteDescription: siteDescription ?? this.siteDescription,
      logoUrl: logoUrl ?? this.logoUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      announcement: announcement ?? this.announcement,
      supportEmail: supportEmail ?? this.supportEmail,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      enableUserRegistration: enableUserRegistration ?? this.enableUserRegistration,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
    );
  }
}

class MuxConfig {
  final String tokenId;
  final String tokenSecret;
  final String environment;
  final bool enable2160pTranscode;
  final String defaultMaxResolutionTier;
  final String defaultVideoQuality;
  final bool enableSignedUrls;
  final String? signingKeyId;
  final String? signingKeySecret;

  const MuxConfig({
    required this.tokenId,
    required this.tokenSecret,
    this.environment = 'production',
    this.enable2160pTranscode = true,
    this.defaultMaxResolutionTier = '2160p',
    this.defaultVideoQuality = 'basic',
    this.enableSignedUrls = false,
    this.signingKeyId,
    this.signingKeySecret,
  });

  MuxConfig copyWith({
    String? tokenId,
    String? tokenSecret,
    String? environment,
    bool? enable2160pTranscode,
    String? defaultMaxResolutionTier,
    String? defaultVideoQuality,
    bool? enableSignedUrls,
    String? signingKeyId,
    String? signingKeySecret,
  }) {
    return MuxConfig(
      tokenId: tokenId ?? this.tokenId,
      tokenSecret: tokenSecret ?? this.tokenSecret,
      environment: environment ?? this.environment,
      enable2160pTranscode: enable2160pTranscode ?? this.enable2160pTranscode,
      defaultMaxResolutionTier:
          defaultMaxResolutionTier ?? this.defaultMaxResolutionTier,
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      enableSignedUrls: enableSignedUrls ?? this.enableSignedUrls,
      signingKeyId: signingKeyId ?? this.signingKeyId,
      signingKeySecret: signingKeySecret ?? this.signingKeySecret,
    );
  }

  String get maskedTokenId {
    if (tokenId.length < 8) return '****';
    return '${tokenId.substring(0, 4)}****${tokenId.substring(tokenId.length - 4)}';
  }

  String get maskedTokenSecret {
    if (tokenSecret.isEmpty) return '****';
    return '****************************';
  }
}

class R2Config {
  final String accountId;
  final String accessKeyId;
  final String secretAccessKey;
  final String bucketName;
  final String publicBaseUrl;
  final String uploadFolder;
  final String region;

  const R2Config({
    required this.accountId,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucketName,
    required this.publicBaseUrl,
    this.uploadFolder = 'videos',
    this.region = 'auto',
  });

  R2Config copyWith({
    String? accountId,
    String? accessKeyId,
    String? secretAccessKey,
    String? bucketName,
    String? publicBaseUrl,
    String? uploadFolder,
    String? region,
  }) {
    return R2Config(
      accountId: accountId ?? this.accountId,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      bucketName: bucketName ?? this.bucketName,
      publicBaseUrl: publicBaseUrl ?? this.publicBaseUrl,
      uploadFolder: uploadFolder ?? this.uploadFolder,
      region: region ?? this.region,
    );
  }

  String get maskedAccountId {
    if (accountId.length < 8) return '****';
    return '${accountId.substring(0, 4)}****${accountId.substring(accountId.length - 4)}';
  }

  String get maskedAccessKeyId {
    if (accessKeyId.length < 8) return '****';
    return '${accessKeyId.substring(0, 4)}****${accessKeyId.substring(accessKeyId.length - 4)}';
  }

  String get maskedSecretAccessKey => '****************************';
}

class PlaybackConfig {
  final String defaultQuality;
  final bool enableAutoQuality;
  final bool enable4kForPremiumOnly;
  final int maxConcurrentStreamsBasic;
  final int maxConcurrentStreamsStandard;
  final int maxConcurrentStreamsPremium;
  final bool enableDolbyAtmos;
  final bool enableHdr;

  const PlaybackConfig({
    this.defaultQuality = '1080p',
    this.enableAutoQuality = true,
    this.enable4kForPremiumOnly = true,
    this.maxConcurrentStreamsBasic = 1,
    this.maxConcurrentStreamsStandard = 2,
    this.maxConcurrentStreamsPremium = 4,
    this.enableDolbyAtmos = true,
    this.enableHdr = true,
  });

  PlaybackConfig copyWith({
    String? defaultQuality,
    bool? enableAutoQuality,
    bool? enable4kForPremiumOnly,
    int? maxConcurrentStreamsBasic,
    int? maxConcurrentStreamsStandard,
    int? maxConcurrentStreamsPremium,
    bool? enableDolbyAtmos,
    bool? enableHdr,
  }) {
    return PlaybackConfig(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      enableAutoQuality: enableAutoQuality ?? this.enableAutoQuality,
      enable4kForPremiumOnly: enable4kForPremiumOnly ?? this.enable4kForPremiumOnly,
      maxConcurrentStreamsBasic:
          maxConcurrentStreamsBasic ?? this.maxConcurrentStreamsBasic,
      maxConcurrentStreamsStandard:
          maxConcurrentStreamsStandard ?? this.maxConcurrentStreamsStandard,
      maxConcurrentStreamsPremium:
          maxConcurrentStreamsPremium ?? this.maxConcurrentStreamsPremium,
      enableDolbyAtmos: enableDolbyAtmos ?? this.enableDolbyAtmos,
      enableHdr: enableHdr ?? this.enableHdr,
    );
  }
}

class SystemConfig {
  final SiteConfig site;
  final MuxConfig mux;
  final R2Config r2;
  final PlaybackConfig playback;
  final DateTime lastUpdatedAt;
  final String? lastUpdatedBy;

  const SystemConfig({
    required this.site,
    required this.mux,
    required this.r2,
    required this.playback,
    required this.lastUpdatedAt,
    this.lastUpdatedBy,
  });

  SystemConfig copyWith({
    SiteConfig? site,
    MuxConfig? mux,
    R2Config? r2,
    PlaybackConfig? playback,
    DateTime? lastUpdatedAt,
    String? lastUpdatedBy,
  }) {
    return SystemConfig(
      site: site ?? this.site,
      mux: mux ?? this.mux,
      r2: r2 ?? this.r2,
      playback: playback ?? this.playback,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }
}
