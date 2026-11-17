import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/auth_service.dart';
import '../ui/login_screen.dart';

class AuthLogic {
  // Logic Proses Register
  static Future<void> handleRegister({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required VoidCallback onStartLoading,
    required VoidCallback onStopLoading,
  }) async {
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar(context, 'Semua kolom wajib diisi!', isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar(context, 'Kata sandi minimal 6 karakter.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar(context, 'Konfirmasi kata sandi tidak cocok.', isError: true);
      return;
    }

    onStartLoading();

    try {
      await AuthService.registerMitra(
        fullName: fullName,
        email: email,
        password: password,
      );

      if (!context.mounted) return;
      _showSnackBar(context, 'Akun berhasil dibuat! Silakan masuk.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on AuthException catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Terjadi kesalahan jaringan. Coba lagi.', isError: true);
    } finally {
      onStopLoading();
    }
  }

  // Logic Proses Login
  static Future<void> handleLogin({
    required BuildContext context,
    required String email,
    required String password,
    required Widget targetScreen,
    required VoidCallback onStartLoading,
    required VoidCallback onStopLoading,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(context, 'Email dan kata sandi wajib diisi!', isError: true);
      return;
    }

    onStartLoading();

    try {
      await AuthService.login(email: email, password: password);

      if (!context.mounted) return;
      _showSnackBar(context, 'Selamat datang kembali!');

      // Hapus seluruh tumpukan halaman Auth agar tidak bisa di-back ke Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Email atau kata sandi salah (${e.message})', isError: true);
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Gagal terhubung ke server.', isError: true);
    } finally {
      onStopLoading();
    }
  }

  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}