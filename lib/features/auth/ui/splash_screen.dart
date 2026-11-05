import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
import 'package:kube/features/auth/ui/welcome_screen.dart';
// import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Background putih bersih
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Logo dan Tagline di Tengah
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo-icon.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kube',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Es batu untuk setiap kebutuhan.',
              style: TextStyle(fontSize: 14, color: AppColors.black50),
            ),
            const SizedBox(height: 48),

            // Loading Bar Biru
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  backgroundColor: AppColors.alto, // Warna dasar abu-abu
                  color: AppColors.cerulean, // Warna bar biru
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 12, color: AppColors.black50),
            ),

            const Spacer(),

            // Status Koneksi di Bawah
            const Text(
              'Connecting to services',
              style: TextStyle(fontSize: 12, color: AppColors.black50),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5), // Hijau pastel
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.circle,
                    color: Color(0xFF10B981),
                    size: 10,
                  ), // Dot hijau
                  SizedBox(width: 6),
                  Text(
                    'Secure connection',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
