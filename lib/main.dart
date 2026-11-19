import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kube/core/config/supabase_config.dart';
import 'package:kube/theme/app_colors.dart';
import 'package:kube/features/auth/service/auth_service.dart';
import 'package:kube/features/auth/ui/splash_screen.dart';
import 'package:kube/features/home/ui/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isRecoveryDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNewPasswordDialog();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _showNewPasswordDialog() {
    if (_isRecoveryDialogOpen) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    _isRecoveryDialogOpen = true;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _RecoveryPasswordDialog(
        onCompleted: () {
          _isRecoveryDialogOpen = false;
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );

          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text(
                'Kata sandi berhasil diperbarui! Selamat datang kembali.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    ).whenComplete(() {
      _isRecoveryDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Kube App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme:
            GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}

class _RecoveryPasswordDialog extends StatefulWidget {
  final VoidCallback onCompleted;

  const _RecoveryPasswordDialog({required this.onCompleted});

  @override
  State<_RecoveryPasswordDialog> createState() =>
      _RecoveryPasswordDialogState();
}

class _RecoveryPasswordDialogState extends State<_RecoveryPasswordDialog> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;
  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.length < 6) {
      setState(() => _errorMsg = 'Kata sandi baru minimal 6 karakter.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMsg = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      await AuthService.updateNewPassword(newPass);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMsg = 'Gagal memperbarui kata sandi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Buat Kata Sandi Baru',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black100,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verifikasi tautan pemulihan berhasil. Silakan masukkan kata sandi baru untuk akun Anda.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.black50,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMsg != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _newPassController,
              obscureText: !_isNewVisible,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Baru',
                hintText: 'Minimal 6 karakter',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _isNewVisible = !_isNewVisible);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassController,
              obscureText: !_isConfirmVisible,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Kata Sandi',
                hintText: 'Ulangi kata sandi baru',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _isConfirmVisible = !_isConfirmVisible);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cerulean,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isSubmitting ? null : _handleSave,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Simpan Kata Sandi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}