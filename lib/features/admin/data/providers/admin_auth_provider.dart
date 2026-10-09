import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/admin_user.dart';
import '../repositories/admin_mock_repository.dart';

class AdminAuthNotifier extends Notifier<AdminAuthState> {
  static const String _prefsTokenKey = 'admin_token';
  static const String _prefsUserIdKey = 'admin_user_id';

  final AdminMockRepository _repo = AdminMockRepository.instance;

  @override
  AdminAuthState build() {
    _restoreFromPrefs();
    return const AdminAuthState();
  }

  Future<void> _restoreFromPrefs() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefsTokenKey);
      final userId = prefs.getString(_prefsUserIdKey);
      if (token != null && userId != null) {
        final user = _repo.getAdminById(userId);
        if (user != null && user.isActive) {
          state = AdminAuthState(
            user: user,
            token: token,
            isAuthenticated: true,
          );
          return;
        }
      }
      state = const AdminAuthState();
    } catch (_) {
      state = const AdminAuthState();
    }
  }

  Future<AdminAuthState> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));
    final result = _repo.authenticate(email, password);
    if (result.isAuthenticated && result.user != null && result.token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsTokenKey, result.token!);
      await prefs.setString(_prefsUserIdKey, result.user!.id);
    }
    state = result.copyWith(isLoading: false);
    return result;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUserIdKey);
    state = const AdminAuthState();
  }

  bool hasPermission(String permission) {
    if (!state.isAuthenticated || state.user == null) return false;
    return state.user!.hasPermission(permission);
  }
}

final adminAuthProvider =
    NotifierProvider<AdminAuthNotifier, AdminAuthState>(AdminAuthNotifier.new);
