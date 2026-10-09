import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_auth_provider.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  final String? redirect;
  const AdminLoginPage({super.key, this.redirect});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _emailCtrl = TextEditingController(text: 'admin@isee.video');
  final _passCtrl = TextEditingController(text: 'admin123');
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(adminAuthProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (result.isAuthenticated) {
      final go = widget.redirect ?? '/admin/dashboard';
      context.go(go);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? '登录失败'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    final loading = auth.isLoading;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://picsum.photos/seed/isee-admin-login/${size.width.toInt()}/${size.height.toInt()}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.78),
                    Colors.black.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 24),
              child: Row(
                children: [
                  const Text(
                    'iSEE',
                    style: TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Text(
                      '管理后台',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('← 返回前台'),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: isWide ? 860 : double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '登录管理后台',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请使用管理员邮箱和密码登录',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: '邮箱地址',
                          labelStyle:
                              const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryRed),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.divider),
                          ),
                          prefixIcon: const Icon(Icons.mail_outline_rounded,
                              color: AppTheme.textMuted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '请输入邮箱';
                          }
                          if (!v.trim().contains('@')) return '邮箱格式不正确';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: '密码',
                          labelStyle:
                              const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryRed),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.divider),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppTheme.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '请输入密码';
                          if (v.length < 6) return '密码长度不足 6 位';
                          return null;
                        },
                        onFieldSubmitted: (_) =>
                            loading ? null : _submit(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('请联系超级管理员重置密码')),
                              );
                            },
                            child: const Text('忘记密码？'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('登 录'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '测试账户',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '超级管理员：admin@isee.video / admin123',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '内容编辑：editor@isee.video / editor123',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '运营分析：analyst@isee.video / analyst123',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
