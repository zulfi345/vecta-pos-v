import '../../../domain/entities/user_entity.dart';

class AuthState {
  final bool isChecking;
  final UserEntity? user;

  /// 'owner' atau 'staff'.
  final String role;
  final String? employeeCode;

  /// Pesan untuk layar masuk (misalnya HP dilepas oleh owner).
  final String? notice;

  const AuthState({
    this.isChecking = false,
    this.user,
    this.role = 'owner',
    this.employeeCode,
    this.notice,
  });

  bool get isAuthenticated => user != null;
  bool get isOwner => role == 'owner';

  AuthState copyWith({
    bool? isChecking,
    UserEntity? user,
    String? role,
    String? employeeCode,
    String? notice,
  }) {
    return AuthState(
      isChecking: isChecking ?? this.isChecking,
      user: user ?? this.user,
      role: role ?? this.role,
      employeeCode: employeeCode ?? this.employeeCode,
      notice: notice ?? this.notice,
    );
  }
}
