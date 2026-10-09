import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../../domain/entities/system_config.dart';

final _systemConfigProvider = StateProvider<SystemConfig>((ref) {
  return AdminMockRepository.instance.getSystemConfig();
});

final _revealStateProvider = StateProvider<Map<String, bool>>((ref) => {});

bool _isRevealed(WidgetRef ref, String key) {
  return ref.watch(_revealStateProvider)[key] ?? false;
}

void _toggleReveal(WidgetRef ref, String key) {
  final map = Map<String, bool>.from(ref.read(_revealStateProvider));
  map[key] = !(map[key] ?? false);
  ref.read(_revealStateProvider.notifier).state = map;
}

class SystemSettingsPage extends ConsumerStatefulWidget {
  final String? id;
  const SystemSettingsPage({super.key, this.id});

  @override
  ConsumerState<SystemSettingsPage> createState() =>
      _SystemSettingsPageState();
}

class _SystemSettingsPageState extends ConsumerState<SystemSettingsPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSideNav(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '系统设置',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                IndexedStack(
                  index: _currentIndex,
                  children: const [
                    _SiteTab(),
                    _MuxTab(),
                    _R2Tab(),
                    _PlaybackTab(),
                    _DangerTab(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideNav() {
    const tabs = [
      (icon: Icons.info_outline_rounded, label: '站点信息'),
      (icon: Icons.smart_display_rounded, label: 'Mux 配置'),
      (icon: Icons.storage_rounded, label: 'R2 存储'),
      (icon: Icons.play_circle_outline_rounded, label: '播放设置'),
      (icon: Icons.dangerous_outlined, label: '危险操作'),
    ];
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: tabs.length,
        separatorBuilder: (_, i) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final selected = _currentIndex == i;
          final isDanger = i == tabs.length - 1;
          return InkWell(
            onTap: () => setState(() => _currentIndex = i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryRed.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: selected
                    ? Border.all(
                        color: isDanger
                            ? AppTheme.primaryRed.withValues(alpha: 0.5)
                            : AppTheme.primaryRed.withValues(alpha: 0.35),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    tabs[i].icon,
                    color: selected
                        ? (isDanger ? AppTheme.primaryRed : AppTheme.primaryRed)
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tabs[i].label,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void _showSavedSnackBar(BuildContext context, [String msg = '已保存']) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ $msg'),
      backgroundColor: const Color(0xFF4ADE80),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class _FieldWrap extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onSave;
  final String? hint;
  const _FieldWrap({
    required this.label,
    required this.child,
    this.onSave,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: child),
          if (onSave != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('保存'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildRevealButton(WidgetRef ref, String key) {
  final revealed = _isRevealed(ref, key);
  return TextButton(
    onPressed: () => _toggleReveal(ref, key),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      revealed ? '隐藏' : '显示',
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    ),
  );
}

Widget _buildInput({
  required TextEditingController ctrl,
  String? hint,
  bool obscure = false,
  bool readOnly = false,
  TextInputType? keyboardType,
  Widget? suffix,
}) {
  return TextFormField(
    controller: ctrl,
    obscureText: obscure,
    readOnly: readOnly,
    keyboardType: keyboardType,
    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppTheme.surfaceLight,
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 40),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

Widget _buildTextArea({
  required TextEditingController ctrl,
  int lines = 4,
  String? hint,
}) {
  return TextFormField(
    controller: ctrl,
    maxLines: lines,
    minLines: lines,
    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppTheme.surfaceLight,
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

Widget _buildSwitchRow(
  bool value,
  ValueChanged<bool> onChanged, [
  String? description,
]) {
  return Row(
    children: [
      Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryRed.withValues(alpha: 0.7),
        activeThumbColor: Colors.white,
        inactiveTrackColor: AppTheme.surfaceLight,
      ),
      if (description != null) ...[
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
          ),
        ),
      ],
    ],
  );
}

class _CardShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _CardShell({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

const List<(String, String)> _kLanguages = [
  ('zh-CN', '简体中文'),
  ('zh-TW', '繁體中文'),
  ('en-US', 'English'),
  ('ja-JP', '日本語'),
  ('ko-KR', '한국어'),
];

const List<(String, String)> _kMuxEnvs = [
  ('production', 'Production 生产环境'),
  ('staging', 'Staging 预发布环境'),
  ('development', 'Development 开发环境'),
];

const List<(String, String)> _kVideoQualities = [
  ('basic', 'Basic（基线）'),
  ('plus', 'Plus（更高码率）'),
  ('premium', 'Premium（专业级）'),
];

const List<(String, String)> _kR2Regions = [
  ('auto', 'Auto 自动'),
  ('wnam', '北美西部'),
  ('enam', '北美东部'),
  ('weur', '欧洲西部'),
  ('eeur', '欧洲东部'),
  ('apac', '亚太'),
];

const List<(String, String)> _kPlaybackQualities = [
  ('360p', '360P 流畅'),
  ('480p', '480P 标清'),
  ('720p', '720P 高清'),
  ('1080p', '1080P 全高清'),
  ('1440p', '2K 超清'),
  ('2160p', '4K 超高清'),
];

class _SiteTab extends ConsumerStatefulWidget {
  const _SiteTab();

  @override
  ConsumerState<_SiteTab> createState() => _SiteTabState();
}

class _SiteTabState extends ConsumerState<_SiteTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _logoCtrl;
  late TextEditingController _faviconCtrl;
  late TextEditingController _annCtrl;
  late TextEditingController _supportCtrl;
  late TextEditingController _mmCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(_systemConfigProvider).site;
    _nameCtrl = TextEditingController(text: s.siteName);
    _descCtrl = TextEditingController(text: s.siteDescription);
    _logoCtrl = TextEditingController(text: s.logoUrl);
    _faviconCtrl = TextEditingController(text: s.faviconUrl);
    _annCtrl = TextEditingController(text: s.announcement ?? '');
    _supportCtrl = TextEditingController(text: s.supportEmail ?? '');
    _mmCtrl = TextEditingController(text: s.maintenanceMessage ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _logoCtrl.dispose();
    _faviconCtrl.dispose();
    _annCtrl.dispose();
    _supportCtrl.dispose();
    _mmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(_systemConfigProvider);
    final site = cfg.site;
    String selectedLang = site.defaultLanguage;
    bool enableReg = site.enableUserRegistration;
    bool mmMode = site.maintenanceMode;

    return _CardShell(
      title: '站点信息配置',
      subtitle: '配置网站基本信息，用户前台会看到这些内容',
      child: StatefulBuilder(
        builder: (ctx, setState2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldWrap(
                label: '站点名称',
                hint: '显示在标题栏和登录页',
                onSave: () => _showSavedSnackBar(ctx, '站点名称已保存'),
                child: _buildInput(ctrl: _nameCtrl, hint: 'iSEE'),
              ),
              _FieldWrap(
                label: '站点描述',
                hint: '用于 SEO 和首页副标题',
                onSave: () => _showSavedSnackBar(ctx, '站点描述已保存'),
                child: _buildTextArea(
                  ctrl: _descCtrl,
                  lines: 2,
                  hint: '一句话描述这个平台...',
                ),
              ),
              _FieldWrap(
                label: 'Logo URL',
                hint: 'PNG/SVG 均可，建议 200x60',
                onSave: () => _showSavedSnackBar(ctx, 'Logo 已保存'),
                child: _buildInput(ctrl: _logoCtrl),
              ),
              _FieldWrap(
                label: 'Favicon URL',
                hint: '浏览器标签页图标',
                onSave: () => _showSavedSnackBar(ctx, 'Favicon 已保存'),
                child: _buildInput(ctrl: _faviconCtrl),
              ),
              _FieldWrap(
                label: '全站公告',
                hint: '顶部横幅公告，留空则不显示',
                onSave: () => _showSavedSnackBar(ctx, '公告已保存'),
                child: _buildTextArea(ctrl: _annCtrl, lines: 3),
              ),
              _FieldWrap(
                label: '客服邮箱',
                hint: '用户联系客服时展示',
                onSave: () => _showSavedSnackBar(ctx, '客服邮箱已保存'),
                child: _buildInput(
                    ctrl: _supportCtrl, hint: 'support@example.com'),
              ),
              _FieldWrap(
                label: '默认语言',
                hint: '新用户首次访问默认语言',
                onSave: () => _showSavedSnackBar(ctx, '默认语言已保存'),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedLang,
                  dropdownColor: AppTheme.surfaceDark,
                  style:
                      const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: _kLanguages
                      .map((l) => DropdownMenuItem(
                            value: l.$1,
                            child: Text('${l.$1}  ·  ${l.$2}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState2(() => selectedLang = v);
                  },
                ),
              ),
              _FieldWrap(
                label: '允许注册',
                hint: '关闭后新用户无法自助注册',
                child: _buildSwitchRow(enableReg, (v) {
                  setState2(() => enableReg = v);
                  final newSite =
                      cfg.site.copyWith(enableUserRegistration: v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(site: newSite);
                }, enableReg ? '当前开启，允许新用户自助注册' : '当前关闭，仅管理员可创建账户'),
                onSave: () => _showSavedSnackBar(ctx, '注册设置已保存'),
              ),
              _FieldWrap(
                label: '维护模式',
                hint: '开启后前台仅显示维护页',
                child: _buildSwitchRow(mmMode, (v) {
                  setState2(() => mmMode = v);
                  final newSite = cfg.site.copyWith(maintenanceMode: v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(site: newSite);
                }, mmMode ? '当前开启，前台所有页面显示维护公告' : '当前关闭，站点正常提供服务'),
                onSave: () => _showSavedSnackBar(ctx, '维护模式设置已保存'),
              ),
              if (mmMode)
                _FieldWrap(
                  label: '维护公告',
                  hint: '前台维护页展示的文字说明',
                  onSave: () => _showSavedSnackBar(ctx, '维护公告已保存'),
                  child: _buildTextArea(
                    ctrl: _mmCtrl,
                    lines: 3,
                    hint: '我们正在升级系统，稍后回来...',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MuxTab extends ConsumerStatefulWidget {
  const _MuxTab();

  @override
  ConsumerState<_MuxTab> createState() => _MuxTabState();
}

class _MuxTabState extends ConsumerState<_MuxTab> {
  late TextEditingController _tidCtrl;
  late TextEditingController _tsCtrl;
  late TextEditingController _mrCtrl;
  late TextEditingController _skIdCtrl;
  late TextEditingController _skSecCtrl;

  @override
  void initState() {
    super.initState();
    final m = ref.read(_systemConfigProvider).mux;
    _tidCtrl = TextEditingController(text: m.tokenId);
    _tsCtrl = TextEditingController(text: m.tokenSecret);
    _mrCtrl = TextEditingController(text: m.defaultMaxResolutionTier);
    _skIdCtrl = TextEditingController(text: m.signingKeyId ?? '');
    _skSecCtrl = TextEditingController(text: m.signingKeySecret ?? '');
  }

  @override
  void dispose() {
    _tidCtrl.dispose();
    _tsCtrl.dispose();
    _mrCtrl.dispose();
    _skIdCtrl.dispose();
    _skSecCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(_systemConfigProvider);
    final mux = cfg.mux;
    bool enable2160 = mux.enable2160pTranscode;
    bool signedUrl = mux.enableSignedUrls;
    String env = mux.environment;
    String vq = mux.defaultVideoQuality;

    return _CardShell(
      title: 'Mux 视频服务配置',
      subtitle: 'Mux.com API 凭证与转码参数设置，请妥善保管密钥',
      child: StatefulBuilder(
        builder: (ctx, setState2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldWrap(
                label: 'Token ID',
                hint: 'Mux 访问 Token ID',
                onSave: () => _showSavedSnackBar(ctx, 'Token ID 已保存'),
                child: _buildInput(
                  ctrl: _tidCtrl,
                  obscure: !_isRevealed(ref, 'mux_tid'),
                  suffix: _buildRevealButton(ref, 'mux_tid'),
                ),
              ),
              _FieldWrap(
                label: 'Token Secret',
                hint: 'Mux 访问密钥（敏感信息）',
                onSave: () => _showSavedSnackBar(ctx, 'Token Secret 已保存'),
                child: _buildInput(
                  ctrl: _tsCtrl,
                  obscure: !_isRevealed(ref, 'mux_ts'),
                  suffix: _buildRevealButton(ref, 'mux_ts'),
                ),
              ),
              _FieldWrap(
                label: '运行环境',
                hint: '影响 API endpoint 和计费',
                onSave: () => _showSavedSnackBar(ctx, '环境设置已保存'),
                child: DropdownButtonFormField<String>(
                  initialValue: env,
                  dropdownColor: AppTheme.surfaceDark,
                  style:
                      const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: _kMuxEnvs
                      .map((e) => DropdownMenuItem(
                            value: e.$1,
                            child: Text(e.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState2(() => env = v);
                  },
                ),
              ),
              _FieldWrap(
                label: '2160p 转码',
                hint: '开启后可输出 4K 视频',
                child: _buildSwitchRow(enable2160, (v) {
                  setState2(() => enable2160 = v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(mux: mux.copyWith(enable2160pTranscode: v));
                }, enable2160 ? '已开启 4K 转码（成本更高）' : '已关闭 4K 转码'),
                onSave: () => _showSavedSnackBar(ctx, '2160p 开关已保存'),
              ),
              _FieldWrap(
                label: '默认分辨率',
                hint: 'max_resolution_tier 默认值',
                onSave: () => _showSavedSnackBar(ctx, '默认分辨率已保存'),
                child: _buildInput(
                    ctrl: _mrCtrl, hint: '2160p / 1440p / 1080p / 720p'),
              ),
              _FieldWrap(
                label: '默认视频质量',
                hint: 'video_quality 参数',
                onSave: () => _showSavedSnackBar(ctx, '视频质量设置已保存'),
                child: DropdownButtonFormField<String>(
                  initialValue: vq,
                  dropdownColor: AppTheme.surfaceDark,
                  style:
                      const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: _kVideoQualities
                      .map((q) => DropdownMenuItem(
                            value: q.$1,
                            child: Text(q.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState2(() => vq = v);
                  },
                ),
              ),
              _FieldWrap(
                label: '签署播放 URL',
                hint: '防盗链：所有播放地址需 JWT 签名',
                child: _buildSwitchRow(signedUrl, (v) {
                  setState2(() => signedUrl = v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(mux: mux.copyWith(enableSignedUrls: v));
                }, signedUrl ? '已开启 URL 签名，未签名链接无法播放' : '未启用，任何人可访问播放链接'),
                onSave: () => _showSavedSnackBar(ctx, '签署 URL 设置已保存'),
              ),
              if (signedUrl) ...[
                _FieldWrap(
                  label: 'Signing Key ID',
                  hint: 'Mux URL 签名 Key ID',
                  onSave: () => _showSavedSnackBar(ctx, 'Key ID 已保存'),
                  child: _buildInput(ctrl: _skIdCtrl),
                ),
                _FieldWrap(
                  label: 'Signing Key Secret',
                  hint: '用于签名 JWT 的私钥（敏感）',
                  onSave: () => _showSavedSnackBar(ctx, 'Signing Secret 已保存'),
                  child: _buildInput(
                    ctrl: _skSecCtrl,
                    obscure: !_isRevealed(ref, 'mux_sk'),
                    suffix: _buildRevealButton(ref, 'mux_sk'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _R2Tab extends ConsumerStatefulWidget {
  const _R2Tab();

  @override
  ConsumerState<_R2Tab> createState() => _R2TabState();
}

class _R2TabState extends ConsumerState<_R2Tab> {
  late TextEditingController _accCtrl;
  late TextEditingController _akCtrl;
  late TextEditingController _skCtrl;
  late TextEditingController _bkCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _folderCtrl;
  late TextEditingController _regionCtrl;

  @override
  void initState() {
    super.initState();
    final r = ref.read(_systemConfigProvider).r2;
    _accCtrl = TextEditingController(text: r.accountId);
    _akCtrl = TextEditingController(text: r.accessKeyId);
    _skCtrl = TextEditingController(text: r.secretAccessKey);
    _bkCtrl = TextEditingController(text: r.bucketName);
    _urlCtrl = TextEditingController(text: r.publicBaseUrl);
    _folderCtrl = TextEditingController(text: r.uploadFolder);
    _regionCtrl = TextEditingController(text: r.region);
  }

  @override
  void dispose() {
    _accCtrl.dispose();
    _akCtrl.dispose();
    _skCtrl.dispose();
    _bkCtrl.dispose();
    _urlCtrl.dispose();
    _folderCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Cloudflare R2 存储配置',
      subtitle: 'S3 兼容对象存储，上传的视频和海报文件存储位置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldWrap(
            label: 'Account ID',
            hint: 'Cloudflare 账户 ID',
            onSave: () => _showSavedSnackBar(context, 'Account ID 已保存'),
            child: _buildInput(
              ctrl: _accCtrl,
              obscure: !_isRevealed(ref, 'r2_acc'),
              suffix: _buildRevealButton(ref, 'r2_acc'),
            ),
          ),
          _FieldWrap(
            label: 'Access Key ID',
            hint: 'R2 S3 API 访问 Key ID',
            onSave: () => _showSavedSnackBar(context, 'Access Key 已保存'),
            child: _buildInput(
              ctrl: _akCtrl,
              obscure: !_isRevealed(ref, 'r2_ak'),
              suffix: _buildRevealButton(ref, 'r2_ak'),
            ),
          ),
          _FieldWrap(
            label: 'Secret Access Key',
            hint: 'S3 API 密钥（最高敏感）',
            onSave: () => _showSavedSnackBar(context, 'Secret Key 已保存'),
            child: _buildInput(
              ctrl: _skCtrl,
              obscure: !_isRevealed(ref, 'r2_sk'),
              suffix: _buildRevealButton(ref, 'r2_sk'),
            ),
          ),
          _FieldWrap(
            label: 'Bucket 名称',
            hint: 'R2 存储桶名',
            onSave: () => _showSavedSnackBar(context, 'Bucket 名称已保存'),
            child: _buildInput(ctrl: _bkCtrl, hint: 'isee-video-prod'),
          ),
          _FieldWrap(
            label: '公网 CDN URL',
            hint: 'R2 自定义域 / R2.dev Public',
            onSave: () => _showSavedSnackBar(context, 'CDN URL 已保存'),
            child: _buildInput(ctrl: _urlCtrl, hint: 'https://cdn.example.com'),
          ),
          _FieldWrap(
            label: '上传子目录',
            hint: '上传时添加到 Key 前缀',
            onSave: () => _showSavedSnackBar(context, '上传子目录已保存'),
            child: _buildInput(ctrl: _folderCtrl, hint: 'videos'),
          ),
          _FieldWrap(
            label: '区域',
            hint: 'R2 bucket 所在区域',
            onSave: () => _showSavedSnackBar(context, '区域已保存'),
            child: DropdownButtonFormField<String>(
              initialValue: _regionCtrl.text,
              dropdownColor: AppTheme.surfaceDark,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              items: _kR2Regions
                  .map((r) => DropdownMenuItem(
                        value: r.$1,
                        child: Text(r.$2),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) _regionCtrl.text = v;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackTab extends ConsumerStatefulWidget {
  const _PlaybackTab();

  @override
  ConsumerState<_PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends ConsumerState<_PlaybackTab> {
  late TextEditingController _basicCtrl;
  late TextEditingController _stdCtrl;

  @override
  void initState() {
    super.initState();
    final p = ref.read(_systemConfigProvider).playback;
    _basicCtrl =
        TextEditingController(text: p.maxConcurrentStreamsBasic.toString());
    _stdCtrl =
        TextEditingController(text: p.maxConcurrentStreamsStandard.toString());
  }

  @override
  void dispose() {
    _basicCtrl.dispose();
    _stdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(_systemConfigProvider);
    final pb = cfg.playback;
    String dq = pb.defaultQuality;
    bool abr = pb.enableAutoQuality;
    bool only4k = pb.enable4kForPremiumOnly;
    bool dolby = pb.enableDolbyAtmos;
    bool hdr = pb.enableHdr;
    int premium = pb.maxConcurrentStreamsPremium;

    return _CardShell(
      title: '播放体验设置',
      subtitle: '视频播放器默认参数和套餐并发流限制',
      child: StatefulBuilder(
        builder: (ctx, setState2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldWrap(
                label: '默认画质',
                hint: '用户首次进入播放器时的档位',
                onSave: () => _showSavedSnackBar(ctx, '默认画质已保存'),
                child: DropdownButtonFormField<String>(
                  initialValue: dq,
                  dropdownColor: AppTheme.surfaceDark,
                  style:
                      const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: _kPlaybackQualities
                      .map((q) => DropdownMenuItem(
                            value: q.$1,
                            child: Text(q.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState2(() => dq = v);
                  },
                ),
              ),
              _FieldWrap(
                label: 'ABR 自动画质',
                hint: '根据带宽自动切换分辨率',
                child: _buildSwitchRow(abr, (v) {
                  setState2(() => abr = v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(playback: pb.copyWith(enableAutoQuality: v));
                }, abr ? '已启用：网速波动时自动切换画质' : '未启用：仅用户手动切换'),
                onSave: () => _showSavedSnackBar(ctx, 'ABR 设置已保存'),
              ),
              _FieldWrap(
                label: '4K 仅高级版',
                hint: '非 Premium 用户无法选择 2160p',
                child: _buildSwitchRow(only4k, (v) {
                  setState2(() => only4k = v);
                  ref.read(_systemConfigProvider.notifier).state = cfg.copyWith(
                      playback: pb.copyWith(enable4kForPremiumOnly: v));
                }, only4k ? '仅 Premium 可看 4K' : '所有会员均可看 4K（若有带宽）'),
                onSave: () => _showSavedSnackBar(ctx, '4K 权限已保存'),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '各套餐并发流限制（同一账号同时播放的设备数）',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _FieldWrap(
                      label: 'Basic 版',
                      onSave: () =>
                          _showSavedSnackBar(ctx, 'Basic 并发数已保存'),
                      child: _buildInput(
                        ctrl: _basicCtrl,
                        keyboardType: TextInputType.number,
                        hint: '1',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FieldWrap(
                      label: 'Standard 版',
                      onSave: () =>
                          _showSavedSnackBar(ctx, 'Standard 并发数已保存'),
                      child: _buildInput(
                        ctrl: _stdCtrl,
                        keyboardType: TextInputType.number,
                        hint: '2',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FieldWrap(
                      label: 'Premium 版',
                      onSave: () =>
                          _showSavedSnackBar(ctx, 'Premium 并发数已保存'),
                      child: _buildInput(
                        ctrl: TextEditingController(text: premium.toString()),
                        keyboardType: TextInputType.number,
                        hint: '4',
                      ),
                    ),
                  ),
                ],
              ),
              _FieldWrap(
                label: '杜比全景声',
                hint: '支持 Dolby Atmos 音频轨',
                child: _buildSwitchRow(dolby, (v) {
                  setState2(() => dolby = v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(playback: pb.copyWith(enableDolbyAtmos: v));
                }, dolby ? '已开启，Premium 可选 Atmos 音轨' : '关闭，仅普通音轨'),
                onSave: () => _showSavedSnackBar(ctx, '杜比设置已保存'),
              ),
              _FieldWrap(
                label: 'HDR 高动态范围',
                hint: 'HDR10 / HDR10+ / Dolby Vision',
                child: _buildSwitchRow(hdr, (v) {
                  setState2(() => hdr = v);
                  ref.read(_systemConfigProvider.notifier).state =
                      cfg.copyWith(playback: pb.copyWith(enableHdr: v));
                }, hdr ? '已开启，支持设备自动输出 HDR' : '关闭，统一输出 SDR'),
                onSave: () => _showSavedSnackBar(ctx, 'HDR 设置已保存'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DangerTab extends StatelessWidget {
  const _DangerTab();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: '危险操作',
      subtitle: '以下操作不可恢复，请确认后再执行，建议先导出数据备份',
      child: Column(
        children: [
          _dangerTile(
            context,
            icon: Icons.cleaning_services_rounded,
            color: const Color(0xFFFBBF24),
            title: '清除全部缓存',
            desc: '清理 Redis / 内存缓存、CDN 边缘节点缓存，首页和播放器可能短暂变慢',
            btnText: '立即清除',
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black54,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side:
                        const BorderSide(color: Color(0xFFFBBF24), width: 1.5),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFBBF24)),
                      SizedBox(width: 10),
                      Text('确认清除缓存？'),
                    ],
                  ),
                  content: const Text(
                    '将清理 CDN 边缘节点缓存、应用层内存缓存、转码进度缓存。\n执行期间首页加载可能变慢，约 1-2 分钟恢复。',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showSavedSnackBar(context, '缓存清除任务已提交（Mock）');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBBF24),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      child: const Text('确认清除'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _dangerTile(
            context,
            icon: Icons.restart_alt_rounded,
            color: AppTheme.primaryRed,
            title: '重置为默认值',
            desc: '所有系统设置（站点、Mux、R2、播放）恢复为出厂默认，当前配置将丢失',
            btnText: '重置所有设置',
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black54,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.dangerous_rounded,
                          color: AppTheme.primaryRed),
                      SizedBox(width: 10),
                      Expanded(child: Text('⚠️ 确认重置为默认值？')),
                    ],
                  ),
                  content: const Text.rich(
                    TextSpan(
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.6),
                      children: [
                        TextSpan(text: '此操作将重置以下内容：\n'),
                        TextSpan(text: '• 站点名称、描述、公告\n'),
                        TextSpan(text: '• Mux API Token 与转码参数\n'),
                        TextSpan(text: '• R2 存储凭证与路径\n'),
                        TextSpan(text: '• 播放器画质与并发设置\n\n'),
                        TextSpan(
                          text: '操作不可撤销，请确认已导出当前配置。',
                          style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.w600),
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
                        Navigator.of(ctx).pop();
                        _showSavedSnackBar(context, '已重置为默认值（Mock）');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      child: const Text('确认重置'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _dangerTile(
            context,
            icon: Icons.cloud_download_rounded,
            color: const Color(0xFF60A5FA),
            title: '导出数据备份',
            desc: '导出当前所有配置（JSON）、管理员列表、套餐设置到本地文件',
            btnText: '开始导出',
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black54,
                builder: (ctx) => const _ExportDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dangerTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String btnText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            label: Text(btnText),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: color == const Color(0xFFFBBF24)
                  ? Colors.black87
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportDialog extends ConsumerStatefulWidget {
  const _ExportDialog();

  @override
  ConsumerState<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<_ExportDialog> {
  late Map<String, bool> _opts;

  @override
  void initState() {
    super.initState();
    _opts = {
      'config': true,
      'admins': false,
      'plans': true,
      'categories': false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.cloud_download_rounded, color: Color(0xFF60A5FA)),
          SizedBox(width: 10),
          Text('选择导出内容'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _exportOpt('系统配置 JSON（site / mux / r2 / playback）', 'config'),
          const SizedBox(height: 8),
          _exportOpt('管理员账户列表', 'admins'),
          const SizedBox(height: 8),
          _exportOpt('会员套餐设置', 'plans'),
          const SizedBox(height: 8),
          _exportOpt('内容分类与榜单', 'categories'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showSavedSnackBar(context, '数据导出中（Mock）...');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF60A5FA),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text('导出 ZIP'),
        ),
      ],
    );
  }

  Widget _exportOpt(String label, String key) {
    final v = _opts[key] ?? false;
    return InkWell(
      onTap: () => setState(() => _opts[key] = !v),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: v,
                onChanged: (nv) => setState(() => _opts[key] = nv ?? v),
                activeColor: const Color(0xFF60A5FA),
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
