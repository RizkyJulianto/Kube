import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

class ExpenseCard extends StatelessWidget {
  final num totalAmount;
  final int totalQty;
  final VoidCallback? onDetailTap;

  const ExpenseCard({
    super.key,
    this.totalAmount = 0,
    this.totalQty = 0,
    this.onDetailTap,
  });

  String _formatRupiah(num amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final reverseIndex = str.length - i;
      if (i > 0 && reverseIndex % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp. $buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.alto),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.credit_card,
                size: 20,
                color: AppColors.cerulean,
              ),
              SizedBox(width: 8),
              Text(
                'Pengeluaran Bulan Ini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatRupiah(totalAmount),
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black100,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Total : ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black70,
                            ),
                          ),
                          TextSpan(
                            text: '$totalQty Sak Es Kristal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: AppColors.black50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onDetailTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cerulean),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Detail Riwayat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cerulean,
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