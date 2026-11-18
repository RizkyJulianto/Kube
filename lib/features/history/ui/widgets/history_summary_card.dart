import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/app_colors.dart';

class HistorySummaryCard extends StatelessWidget {
  final String filterLabel;
  final num totalSpending;
  final int totalSacks;
  final int unpaidCount;
  final VoidCallback onExportTap;

  const HistorySummaryCard({
    super.key,
    required this.filterLabel,
    required this.totalSpending,
    required this.totalSacks,
    required this.unpaidCount,
    required this.onExportTap,
  });

  String _formatRupiah(num amount) {
    final intVal = amount.round();
    return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final isAllPaid = unpaidCount == 0 && totalSacks > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate Dark
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Transaksi ($filterLabel)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
              InkWell(
                onTap: onExportTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pattensBlue.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.file_download_outlined,
                        size: 14,
                        color: AppColors.cerulean,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Rekap Nota',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cerulean,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp. ${_formatRupiah(totalSpending)}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total : $totalSacks Sak Es Kristal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllPaid
                      ? const Color(0xFFD1FAE5)
                      : (totalSacks == 0
                          ? Colors.white12
                          : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalSacks == 0
                      ? 'Belum Ada Data'
                      : (isAllPaid
                          ? 'Semua Lunas'
                          : '$unpaidCount Belum Lunas'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAllPaid
                        ? const Color(0xFF059669)
                        : (totalSacks == 0
                            ? Colors.white70
                            : const Color(0xFFD97706)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}