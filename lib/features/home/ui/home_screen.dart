import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../profile/ui/profile_screen.dart';

// Pastikan path import widget ini sesuai dengan folder kamu
import 'widgets/quick_reorder_card.dart';
import 'widgets/expense_card.dart';
import 'widgets/tracking_card.dart';
import 'widgets/support_card.dart';
import 'widgets/operational_tips_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Logo & Profile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo-icon.png',
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Kube',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Selamat Pagi, Sofyan Khoiron 👋',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.black50,
                      ),
                    ),
                  ],
                ),
                
                // Avatar Profil yang bisa diklik ke Halaman Profil
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.pattensBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cerulean.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'SK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.cerulean,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kumpulan Kartu Beranda (Pastikan widget ini sudah ada file-nya)
            const QuickReorderCard(),
            const SizedBox(height: 16),
            const ExpenseCard(),
            const SizedBox(height: 16),
            const TrackingCard(),
            const SizedBox(height: 16),
            const SupportCard(),
            const SizedBox(height: 16),
            const OperationalTipsCard(),
          ],
        ),
      ),
      
      // Bottom Navigation Bar dipanggil langsung (index 0 = Beranda)
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}