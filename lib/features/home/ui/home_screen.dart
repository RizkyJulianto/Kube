import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../profile/service/profile_service.dart';
import '../../profile/ui/profile_screen.dart';
import '../service/home_service.dart';

import 'widgets/quick_reorder_card.dart';
import 'widgets/expense_card.dart';
import 'widgets/tracking_card.dart';
import 'widgets/support_card.dart';
import 'widgets/operational_tips_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State {
  String _userName = 'Mitra Kube';
  String _initials = 'MK';
  Map? _lastOrder;
  Map? _activeOrder;
  num _monthlyTotal = 0;
  int _monthlyQty = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future _loadDashboardData() async {
    await Future.wait([
      _loadUserHeader(),
      _loadSummary(),
    ]);
  }

  Future _loadUserHeader() async {
    try {
      final data = await ProfileService.getMitraProfile();
      final user = data['user'] as Map;
      final name = (user['name'] ?? 'Mitra Kube').toString().trim();

      if (!mounted) return;
      setState(() {
        _userName = name.isNotEmpty ? name : 'Mitra Kube';
        _initials = _getInitials(_userName);
      });
    } catch (_) {}
  }

  Future _loadSummary() async {
    try {
      final summary = await HomeService.getHomeSummary();
      if (!mounted) return;
      setState(() {
        _lastOrder = summary['lastOrder'] as Map?;
        _activeOrder = summary['activeOrder'] as Map?;
        _monthlyTotal = (summary['monthlyTotal'] as num?) ?? 0;
        _monthlyQty = (summary['monthlyQty'] as int?) ?? 0;
      });
    } catch (_) {}
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'MK';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cerulean,
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Logo & Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                        Text(
                          '${_getGreeting()}, $_userName 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.black50,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ).then((_) => _loadUserHeader());
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.pattensBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cerulean.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
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

              // 1. Kartu Order Cepat (MITRA BARU jika belum pernah pesan)
              QuickReorderCard(
                lastOrder: _lastOrder,
                onActionTap: () {
                  // Nanti diarahkan ke halaman Pesan / Checkout ulang
                },
              ),
              const SizedBox(height: 16),

              // 2. Kartu Pengeluaran Bulan Ini (Rp. 0 jika belum ada transaksi)
              ExpenseCard(
                totalAmount: _monthlyTotal,
                totalQty: _monthlyQty,
                onDetailTap: () {
                  // Nanti diarahkan ke tab Riwayat
                },
              ),
              const SizedBox(height: 16),

              // 3. Kartu Ringkasan Pengiriman (otomatis tersembunyi jika tidak ada pesanan aktif)
              TrackingCard(
                activeOrder: _activeOrder,
                onTrackTap: () {
                  // Nanti diarahkan ke tab Lacak
                },
              ),

              // 4. Kartu Bantuan & Komplain
              const SupportCard(),
              const SizedBox(height: 16),

              // 5. Kartu Tips Operasional
              const OperationalTipsCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}