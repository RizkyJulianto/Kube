import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class OperationalTipsCard extends StatelessWidget {
  const OperationalTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icons.ac_unit_rounded,
              color: AppColors.cerulean,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Tips Operasional : ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black100,
                    ),
                  ),
                  TextSpan(
                    text: 'Cek level freezer sebelum jam sibuk. Estimasi pengiriman instan rata-rata 25 menit.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.black50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}