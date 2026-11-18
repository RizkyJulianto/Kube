import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/app_colors.dart';

class TransactionCard extends StatelessWidget {
  final String orderCode;
  final String date;
  final String productSummary;
  final String deliveryDetail;
  final String price;
  final String paymentMethodName;
  final String orderStatus;
  final String paymentStatus;
  final bool isScheduled;
  final VoidCallback onDetailTap;

  const TransactionCard({
    super.key,
    required this.orderCode,
    required this.date,
    required this.productSummary,
    required this.deliveryDetail,
    required this.price,
    required this.paymentMethodName,
    required this.orderStatus,
    required this.paymentStatus,
    required this.isScheduled,
    required this.onDetailTap,
  });

  Map<String, dynamic> _getOrderStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return {
          'label': 'Selesai',
          'bg': const Color(0xFFD1FAE5),
          'fg': const Color(0xFF059669),
        };
      case 'on_delivery':
      case 'shipping':
        return {
          'label': 'Dikirim',
          'bg': const Color(0xFFE0F2FE),
          'fg': const Color(0xFF0284C7),
        };
      case 'processing':
      case 'confirmed':
        return {
          'label': 'Diproses',
          'bg': const Color(0xFFEDE9FE),
          'fg': const Color(0xFF7C3AED),
        };
      case 'cancelled':
      case 'failed':
        return {
          'label': 'Dibatalkan',
          'bg': const Color(0xFFFEE2E2),
          'fg': const Color(0xFFDC2626),
        };
      default:
        return {
          'label': 'Menunggu',
          'bg': const Color(0xFFFEF3C7),
          'fg': const Color(0xFFD97706),
        };
    }
  }

  Map<String, dynamic> _getPaymentBadge(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return {
          'label': 'Lunas',
          'bg': const Color(0xFFD1FAE5),
          'fg': const Color(0xFF059669),
        };
      case 'waiting_verification':
        return {
          'label': 'Verifikasi',
          'bg': const Color(0xFFE0F2FE),
          'fg': const Color(0xFF0284C7),
        };
      case 'fail':
      case 'failed':
        return {
          'label': 'Gagal',
          'bg': const Color(0xFFFEE2E2),
          'fg': const Color(0xFFDC2626),
        };
      default:
        return {
          'label': 'Belum Bayar',
          'bg': const Color(0xFFFEF3C7),
          'fg': const Color(0xFFD97706),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBadge = _getOrderStatusBadge(orderStatus);
    final payBadge = _getPaymentBadge(paymentStatus);

    return InkWell(
      onTap: onDetailTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          orderCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusBadge['bg'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusBadge['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusBadge['fg'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: AppColors.black50),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pattensBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isScheduled
                        ? Icons.event_repeat_rounded
                        : Icons.receipt_long_outlined,
                    color: AppColors.cerulean,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productSummary,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        deliveryDetail,
                        maxLines: 2,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp. $price',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: payBadge['bg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$paymentMethodName • ${payBadge['label']}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: payBadge['fg'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.alto),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isScheduled
                          ? Icons.schedule_rounded
                          : Icons.flash_on_rounded,
                      size: 14,
                      color: AppColors.cerulean,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isScheduled ? 'Jadwal Harian' : 'Kirim Langsung',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black70,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.text_snippet_outlined,
                      size: 14,
                      color: AppColors.cerulean,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lihat Nota',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cerulean,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}