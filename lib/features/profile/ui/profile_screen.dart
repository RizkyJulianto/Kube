import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../auth/service/auth_service.dart';
import '../../auth/ui/login_screen.dart';
import '../service/profile_service.dart';
import 'delivery_address_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _cafeName = 'Nama Outlet Belum Diatur';
  String _fullName = 'Mitra Kube';
  String _phone = '-';
  String _email = '';
  String _address = '';
  double? _latitude;
  double? _longitude;
  String _mitraCode = '#Mitra';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ProfileService.getMitraProfile();
      final user = data['user'] as Map<String, dynamic>;
      final consumer = data['consumer'] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _fullName = user['name'] ?? 'Mitra Kube';
        _email = user['email'] ?? '';
        _phone = (user['phone'] != null && user['phone'].toString().isNotEmpty)
            ? user['phone']
            : 'No. HP belum diisi';

        _cafeName = (consumer['cafe_name'] != null && consumer['cafe_name'].toString().isNotEmpty)
            ? consumer['cafe_name']
            : 'Nama Kafe Belum Diatur';
        _address = consumer['address'] ?? '';
        _latitude = (consumer['latitude'] as num?)?.toDouble();
        _longitude = (consumer['longitude'] as num?)?.toDouble();

        final consumerId = consumer['id'];
        _mitraCode = consumerId != null ? 'ID #Mitra - $consumerId' : 'ID #Mitra';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat profil: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black100),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cerulean))
            : RefreshIndicator(
                color: AppColors.cerulean,
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    const Text(
                      'Kelola Data Pengguna & Pengaturan',
                      style: TextStyle(fontSize: 13, color: AppColors.black50),
                    ),
                    const SizedBox(height: 20),

                    // 1. Kartu Profil Pengguna (Dinamis dari Database)
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
                                Text(
                                  _cafeName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black100,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_fullName - $_phone',
                                  style: const TextStyle(fontSize: 11, color: AppColors.black70),
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
                                    Text(
                                      _mitraCode,
                                      style: const TextStyle(
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

                    // 2. Pengaturan Akun & Alamat
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
                            subtitle: 'Ubah nama kafe, penanggung jawab & No HP',
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(
                                    initialCafeName: _cafeName == 'Nama Kafe Belum Diatur' ? '' : _cafeName,
                                    initialName: _fullName,
                                    initialPhone: _phone == 'No. HP belum diisi' ? '' : _phone,
                                    email: _email,
                                  ),
                                ),
                              );
                              if (updated == true) _loadProfile();
                            },
                          ),
                          const Divider(height: 1, color: AppColors.alto),
                          _buildMenuTile(
                            icon: Icons.location_on_outlined,
                            title: 'Alamat Pengiriman',
                            subtitle: _address.isNotEmpty
                                ? _address
                                : 'Belum diatur — kelola alamat & titik lokasi outlet',
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeliveryAddressScreen(
                                    initialAddress: _address,
                                    initialLat: _latitude,
                                    initialLng: _longitude,
                                  ),
                                ),
                              );
                              if (updated == true) _loadProfile();
                            },
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

                    // 3. Pusat Informasi & Bantuan
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

                    // 4. Tombol Keluar Akun (Aktif Logout)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: AppColors.alto),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleLogout,
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
                        style: TextStyle(fontSize: 11, color: AppColors.black50),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black100),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.black50),
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