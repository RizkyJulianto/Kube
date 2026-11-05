import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Index status dummy (0: Pending, 1: Processing, 2: Delivering, 3: Completed)
  int _currentStep = 2; // Ubah ke 3 untuk tes tampilan Selesai (Completed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black100),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lacak Pengiriman',
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
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Card Step Timeline Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STATUS PESANAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black50,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Order #ORD-8821',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timeline Step Indicator
                  Row(
                    children: [
                      _buildStepNode(0, 'Dibuat', Icons.receipt_long_outlined),
                      _buildStepLine(0),
                      _buildStepNode(1, 'Diproses', Icons.inventory_2_outlined),
                      _buildStepLine(1),
                      _buildStepNode(2, 'Diantar', Icons.local_shipping_outlined),
                      _buildStepLine(2),
                      _buildStepNode(3, 'Selesai', Icons.check_circle_outline_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Banner Status Pengiriman Utama (Dinamis)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentStep == 3 ? const Color(0xFFD1FAE5) : AppColors.pattensBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentStep == 3 ? const Color(0xFF10B981) : AppColors.cerulean.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _currentStep == 3 ? const Color(0xFF10B981) : AppColors.cerulean,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentStep == 3 ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 3 ? 'Pesanan Telah Tiba' : 'Kurir sedang dalam perjalanan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentStep == 3 ? 'Es batu sudah diterima di lokasi kafe' : 'Estimasi tiba: 15 - 20 Menit lagi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _currentStep == 3 ? const Color(0xFF059669) : AppColors.cerulean,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Info Driver & Kontak
            const Text(
              'INFORMASI DRIVER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.cerulean,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('MS', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'Maryono Supardi',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black100),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 14),
                            Text(' 4.9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCA8A04))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Truk Isuzu - H 1928 BA',
                          style: TextStyle(fontSize: 11, color: AppColors.black50),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cerulean),
                    ),
                    child: const Icon(Icons.phone_outlined, color: AppColors.cerulean, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Detail Rincian Barang & Alamat Tujuan
            const Text(
              'RINCIAN PENGIRIMAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.cerulean, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Kopi Senja - Watumas',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black100),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Jl. HR Bunyamin No. 108, Purwokerto Utara',
                              style: TextStyle(fontSize: 11, color: AppColors.black50),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.alto),
                  Row(
                    children: [
                      const Icon(Icons.ac_unit_rounded, color: AppColors.cerulean, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Muatan: 10 Sak Ice Tube (100 Kg)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100),
                        ),
                      ),
                      Text(
                        'Rp 150.000',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Catatan: Taruh di dalam freezer bagian belakang kafe.',
                      style: TextStyle(fontSize: 11, color: AppColors.black70, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. TOMBOL CALL-TO-ACTION (CTA) DINAMIS
            if (_currentStep == 2) ...[
              // CTA saat status Delivering
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.alto),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.white,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.support_agent_rounded, color: AppColors.black100, size: 20),
                  label: const Text(
                    'Bantuan / Komplain Pesanan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black100),
                  ),
                ),
              ),
            ] else if (_currentStep == 3) ...[
              // CTA saat status Completed (Selesai)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Hijau Sukses
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.white, size: 20),
                  label: const Text(
                    'Konfirmasi Pesanan Diterima',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cerulean),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.cerulean, size: 20),
                  label: const Text(
                    'Pesan Lagi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cerulean),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildStepNode(int index, String label, IconData icon) {
    final bool isCompleted = index <= _currentStep;
    final bool isCurrent = index == _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.cerulean : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? AppColors.cerulean : AppColors.alto,
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [BoxShadow(color: AppColors.cerulean.withOpacity(0.4), blurRadius: 8)]
                  : [],
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted ? AppColors.white : AppColors.black50,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? AppColors.black100 : AppColors.black50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int index) {
    final bool isCompleted = index < _currentStep;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isCompleted ? AppColors.cerulean : AppColors.alto,
    );
  }
}