import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/services/account_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/user_usecases.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  AccountService get _account => ref.read(accountServiceProvider);

  Timer? _watch;

  @override
  AuthState build() {
    ref.onDispose(() => _watch?.cancel());
    _initialize();
    return const AuthState(isChecking: true);
  }

  Future<void> _initialize() async {
    // Tunda sampai build() selesai agar state tidak tertimpa isChecking: true.
    await Future<void>.microtask(() {});
    try {
      final saved = _account.savedSession;
      if (saved == null) {
        state = const AuthState();
        return;
      }

      final res = await _account.verifySaved(saved);
      final status = res['status'];

      if (status == 'active') {
        await _account.saveExpiry(res['expired_at'] as DateTime);
        await _enter(saved);
      } else if (status == 'offline_error') {
        if (_account.isCacheValid()) {
          await _enter(saved);
        } else {
          state = const AuthState(
            notice: 'Tidak ada koneksi internet. Sambungkan internet untuk masuk.',
          );
        }
      } else {
        await _account.clearSession();
        state = AuthState(notice: res['message']?.toString());
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> _enter(AccountSession s) async {
    final user = UserEntity(id: s.userId, email: s.email, name: s.name);
    await CreateUserUsecase(ref.read(userRepositoryProvider)).call(user);
    state = AuthState(user: user, role: s.role, employeeCode: s.employeeCode);
    _startWatch();
  }

  /// Cek ulang ke server tiap 10 menit selama aplikasi terbuka, supaya blokir,
  /// langganan habis, atau HP yang dilepas langsung berlaku.
  void _startWatch() {
    _watch?.cancel();
    _watch = Timer.periodic(const Duration(minutes: 10), (_) => _recheck());
  }

  Future<void> _recheck() async {
    if (state.user == null) return;
    final saved = _account.savedSession;
    if (saved == null) return;
    try {
      final res = await _account.verifySaved(saved);
      final status = res['status'];
      if (status == 'active') {
        await _account.saveExpiry(res['expired_at'] as DateTime);
      } else if (status == 'offline_error') {
        if (!_account.isCacheValid()) {
          _watch?.cancel();
          state = const AuthState(
            notice: 'Sudah terlalu lama offline. Sambungkan internet untuk masuk.',
          );
        }
      } else {
        _watch?.cancel();
        await _account.clearSession();
        state = AuthState(notice: res['message']?.toString());
      }
    } catch (_) {
      // Abaikan; dicek lagi pada putaran berikutnya.
    }
  }

  Future<Result<String>> _complete(Map<String, dynamic> res) async {
    if (res['status'] != 'active') {
      return Result.failure(error: res['message']?.toString() ?? 'Gagal masuk.');
    }
    final saved = _account.savedSession;
    if (saved == null) return Result.failure(error: 'Sesi gagal disimpan.');
    await _enter(saved);
    return Result.success(data: saved.userId);
  }

  Future<Result<String>> registerOwner(String email, String password) async =>
      _complete(await _account.registerOwner(email, password));

  Future<Result<String>> signInOwner(String email, String password) async =>
      _complete(await _account.signInOwner(email, password));

  Future<Result<String>> signInStaff(String email, String pin) async =>
      _complete(await _account.signInStaff(email, pin));

  Future<Result<void>> signOut() async {
    _watch?.cancel();
    await _account.signOut();
    state = const AuthState();
    return Result.success(data: null);
  }
}
