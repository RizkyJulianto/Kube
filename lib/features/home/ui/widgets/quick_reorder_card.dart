import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

class QuickReorderCard extends StatelessWidget {
  const QuickReorderCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: const Text(
                  'PESANAN TERAKHIR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cerulean,
                  ),
                ),
              ),
              // Waktu menggunakan Font Inter
              Text(
                'Kemarin, 14.20',
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
            'Order Cepat',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.black100,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '10 Kantong ice (10 Kg)',
            style: TextStyle(
              fontSize: 14,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Sampai',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.black50,
                        ),
                      ),
                      // Angka menit menggunakan Font Inter
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

          // Tombol Pesan Lagi
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
              onPressed: () {},
              child: const Text(
                'Pesan Lagi',
                style: TextStyle(
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