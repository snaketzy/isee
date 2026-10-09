import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import 'admin_sidebar.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final String pageTitle;

  const AdminShell({
    super.key,
    required this.child,
    this.appBar,
    required this.pageTitle,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _sidebarCollapsed = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useDrawer = width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundDark,
      drawer: useDrawer
          ? SizedBox(
              width: 256,
              child: Drawer(
                backgroundColor: AppTheme.surfaceDark,
                child: AdminSidebar(
                  collapsed: false,
                  onToggle: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!useDrawer)
            AdminSidebar(
              collapsed: _sidebarCollapsed,
              onToggle: _toggleSidebar,
            ),
          Expanded(
            child: Column(
              children: [
                if (widget.appBar != null) widget.appBar!,
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
