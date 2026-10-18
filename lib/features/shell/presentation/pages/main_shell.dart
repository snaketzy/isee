import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/platform/platform.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _routes = ['/home', '/search', '/mylist', '/profile'];
  static const _labels = ['首页', '搜索', '片单', '我的'];
  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.bookmark_rounded,
    Icons.person_rounded,
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loc = GoRouterState.of(context).uri.path;
    final idx = _routes.indexWhere((r) => loc.startsWith(r));
    if (idx >= 0 && idx != _currentIndex) {
      _currentIndex = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 56 : 64),
        child: _AnimatedAppBar(
          isHome: GoRouterState.of(context).uri.path == '/home',
          onLogoTap: () => context.go('/home'),
          onSearchTap: () => context.go('/search'),
          onProfileTap: () => context.go('/profile'),
          onNotifTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('暂无新通知')),
            );
          },
        ),
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surfaceDark.withOpacity(0.95),
        indicatorColor: AppTheme.primaryRed.withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        height: isMobile ? 60 : 64,
        destinations: List.generate(4, (i) {
          return NavigationDestination(
            icon: Icon(_icons[i], color: AppTheme.textSecondary),
            selectedIcon: Icon(_icons[i], color: AppTheme.textPrimary),
            label: _labels[i],
          );
        }),
      ),
    );
  }
}

class _AnimatedAppBar extends StatefulWidget {
  final bool isHome;
  final VoidCallback onLogoTap;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotifTap;

  const _AnimatedAppBar({
    required this.isHome,
    required this.onLogoTap,
    required this.onSearchTap,
    required this.onProfileTap,
    required this.onNotifTap,
  });

  @override
  State<_AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<_AnimatedAppBar> {
  bool _isScrolled = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final scrolled = notification.metrics.pixels > 20;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    if (!widget.isHome) {
      _isScrolled = true;
    }
    final bgColor = _isScrolled || !widget.isHome
        ? AppTheme.backgroundDark.withOpacity(0.96)
        : Colors.transparent;

    return NotificationListener<ScrollNotification>(
      onNotification: widget.isHome ? _handleScrollNotification : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24, vertical: isMobile ? 6 : 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onLogoTap,
                  child: Text(
                    'iSee',
                    style: TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                if (!isMobile) const SizedBox(width: 32),
                if (!isMobile && widget.isHome) _buildNavLinks(),
                const Spacer(),
                IconButton(
                  onPressed: widget.onSearchTap,
                  icon: const Icon(Icons.search_rounded),
                  tooltip: '搜索',
                  iconSize: isMobile ? 22 : 24,
                ),
                if (!isMobile) const SizedBox(width: 4),
                if (!isMobile)
                  IconButton(
                    onPressed: widget.onNotifTap,
                    icon: const Icon(Icons.notifications_none_rounded),
                    tooltip: '通知',
                  ),
                SizedBox(width: isMobile ? 4 : 8),
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: Container(
                    width: isMobile ? 30 : 34,
                    height: isMobile ? 30 : 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryRed, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavLinks() {
    final links = const ['首页', '剧集', '电影', '新片与热门', '我的片单'];
    return Row(
      children: List.generate(links.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            links[i],
            style: TextStyle(
              fontSize: 14,
              color: i == 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }),
    );
  }
}
