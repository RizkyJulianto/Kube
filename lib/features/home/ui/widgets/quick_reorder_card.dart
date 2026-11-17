import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

class QuickReorderCard extends StatelessWidget {
  final Map? lastOrder;
  final VoidCallback? onActionTap;

  const QuickReorderCard({
    super.key,
    this.lastOrder,
    this.onActionTap,
  });

  String _formatOrderDate(String? isoDate) {
    if (isoDate == null) return '-';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '-';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDay = DateTime(dt.year, dt.month, dt.day);

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (orderDay == today) return 'Hari ini, $hh.$mm';
    if (orderDay == yesterday) return 'Kemarin, $hh.$mm';
    return '${dt.day}/${dt.month}/${dt.year}, $hh.$mm';
  }

  String _buildItemsSummary(List items) {
    if (items.isEmpty) return 'Pesanan Es Kristal';
    final summaries = [];
    for (final item in items) {
      final qty = item['quantity'] ?? 0;
      final product = item['products'] as Map?;
      final name = product?['name'] ?? 'Es Kristal';
      final unit = product?['unit'] ?? 'Kantong';
      summaries.add('$qty $unit $name');
    }
    return summaries.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOrder = lastOrder != null;
    final List items = hasOrder ? ((lastOrder!['order_items'] as List?) ?? []) : [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.alto),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Badge & Waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pattensBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasOrder ? 'PESANAN TERAKHIR' : 'MITRA BARU',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cerulean,
                  ),
                ),
              ),
              Text(
                hasOrder ? _formatOrderDate(lastOrder!['created_at']?.toString()) : 'Siap Kirim',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.black50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Judul Utama
          Text(
            hasOrder ? 'Order Cepat' : 'Mulai Pesan Stok',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.black100,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasOrder
                ? _buildItemsSummary(items)
                : 'Belum ada riwayat pesanan. Pesan stok es kristal pertamamu sekarang!',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.black50,
            ),
          ),
          const SizedBox(height: 16),

          // Banner Estimasi Pengiriman
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pattensBlue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pattensBlue),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.ac_unit,
                  color: AppColors.cerulean,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Sampai',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.black50,
                        ),
                      ),
                      Text(
                        '< 30 Menit , Truk Cepat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Hemat 10%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cerulean,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Pesan Lagi / Pesan Sekarang
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cerulean,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onActionTap,
              child: Text(
                hasOrder ? 'Pesan Lagi' : 'Pesan Sekarang',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}