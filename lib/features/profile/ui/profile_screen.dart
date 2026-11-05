import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black100),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Pengguna',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black100,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            const Text(
              'Kelola Data Pengguna & Pengaturan',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.black50,
              ),
            ),
            const SizedBox(height: 20),

            // 1. Kartu Profil Pengguna (Existing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cerulean, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.coffee_maker_outlined, color: AppColors.cerulean, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kopi Senja - Watumas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sofyan Khoiron - 081234567889',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.black70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.pattensBlue,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cerulean.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Mitra Aktif',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cerulean,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ID #Mitra - 772',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black50,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Pengaturan Akun & Alamat (BARU)
            const Text(
              'PENGATURAN AKUN & ALAMAT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profil & Kontak',
                    subtitle: 'Ubah nama penanggung jawab & No HP',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.alto),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Alamat Pengiriman',
                    subtitle: 'Kelola titik pin peta lokasi outlet',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.alto),
                  _buildMenuTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Pengaturan Notifikasi',
                    subtitle: 'Atur pemberitahuan pengiriman truk',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Pusat Informasi & Bantuan (Existing)
            const Text(
              'PUSAT INFORMASI & BANTUAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Pusat Bantuan & Komplain',
                    subtitle: 'Hubungi Customer Service',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.alto),
                  _buildMenuTile(
                    icon: Icons.description_outlined,
                    title: 'Syarat & Ketentuan',
                    subtitle: 'Aturan Pemesanan & Garansi',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.alto),
                  _buildMenuTile(
                    icon: Icons.shield_outlined,
                    title: 'Kebijakan Privasi',
                    subtitle: 'Perlindungan Data Akun & Transaksi',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Tombol Keluar Akun
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9), // Abu-abu sangat muda
                  side: const BorderSide(color: AppColors.alto),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Keluar Akun',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Versi Aplikasi
            const Center(
              child: Text(
                'Versi Aplikasi Kube v4.20',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.black50,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper Widget untuk Menu Tile (Bisa dipakai ulang berkali-kali)
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pattensBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.cerulean, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black100,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.black50,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.cerulean, size: 24),
          ],
        ),
      ),
    );
  }
}