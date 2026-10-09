enum AdminRole { superAdmin, contentEditor, analyst }

extension AdminRoleExtension on AdminRole {
  String get label {
    switch (this) {
      case AdminRole.superAdmin:
        return '超级管理员';
      case AdminRole.contentEditor:
        return '内容编辑';
      case AdminRole.analyst:
        return '运营分析师';
    }
  }

  String get shortLabel {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super';
      case AdminRole.contentEditor:
        return 'Editor';
      case AdminRole.analyst:
        return 'Analyst';
    }
  }

  List<String> get permissions {
    switch (this) {
      case AdminRole.superAdmin:
        return const [
          'dashboard.view',
          'content.view',
          'content.edit',
          'content.delete',
          'media.view',
          'media.upload',
          'users.view',
          'users.edit',
          'subscription.view',
          'subscription.edit',
          'analytics.view',
          'admin.manage',
          'settings.manage',
        ];
      case AdminRole.contentEditor:
        return const [
          'dashboard.view',
          'content.view',
          'content.edit',
          'media.view',
          'media.upload',
          'analytics.view',
        ];
      case AdminRole.analyst:
        return const [
          'dashboard.view',
          'content.view',
          'users.view',
          'analytics.view',
        ];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}

class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final AdminRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final int loginCount;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.lastLoginIp,
    this.loginCount = 0,
  });

  bool hasPermission(String permission) => role.hasPermission(permission);

  AdminUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    AdminRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    int? loginCount,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      loginCount: loginCount ?? this.loginCount,
    );
  }
}

class AdminAuthState {
  final AdminUser? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AdminAuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AdminAuthState copyWith({
    AdminUser? user,
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminAuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
