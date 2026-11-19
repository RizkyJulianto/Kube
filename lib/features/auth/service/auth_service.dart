import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static Future<AuthResponse> registerMitra({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 'mitra',
      },
    );
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Mengirim tautan pemulihan kata sandi sesuai platform (Web vs Mobile)
  static Future<void> sendPasswordResetEmail(String email) async {
    final redirectUrl = kIsWeb
        ? Uri.base.origin
        : 'io.supabase.kube://reset-callback/';

    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  /// Memperbarui kata sandi setelah pengguna membuka tautan pemulihan (recovery session)
  static Future<void> updateNewPassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  /// Mengubah kata sandi saat pengguna sudah login (untuk menu Profil)
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('Sesi akun tidak ditemukan. Silakan login ulang.');
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword.trim(),
    );

    await _client.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }
}