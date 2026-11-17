import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

class TrackingCard extends StatelessWidget {
  final Map? activeOrder;
  final VoidCallback? onTrackTap;

  const TrackingCard({
    super.key,
    this.activeOrder,
    this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sembunyikan kartu jika user belum pernah pesan atau tidak ada pesanan aktif
    if (activeOrder == null) {
      return const SizedBox.shrink();
    }

    final status = (activeOrder!['status'] ?? 'pending').toString();
    final orderId = activeOrder!['id']?.toString() ?? '-';

    // Ambil nama kurir dari relasi courier_profiles -> users (jika sudah ditugaskan)
    final courierProfile = activeOrder!['courier_profiles'] as Map?;
    final courierUser = courierProfile?['users'] as Map?;
    final courierName = courierUser?['name']?.toString();

    String titlePrefix = 'Pesanan sedang ';
    String titleHighlight = 'diproses';
    String subtitle = 'Order #$orderId menunggu konfirmasi admin';

    if (status == 'processing') {
      titlePrefix = 'Stok sedang ';
      titleHighlight = 'disiapkan';
      subtitle = courierName != null && courierName.isNotEmpty
          ? 'Kurir $courierName bersiap menjemput pesanan'
          : 'Menunggu penugasan kurir pengiriman';
    } else if (status == 'delivering') {
      titlePrefix = 'Pengiriman ';
      titleHighlight = 'dalam perjalanan';
      subtitle = courierName != null && courierName.isNotEmpty
          ? 'Kurir $courierName sedang menuju lokasi outlet'
          : 'Armada Kube sedang menuju lokasi outlet';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.alto),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pattensBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.cerulean,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: titlePrefix,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                        TextSpan(
                          text: titleHighlight,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cerulean,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.black50,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTrackTap,
              child: const Row(
                children: [
                  Text(
                    'Lacak',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cerulean,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.cerulean),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}