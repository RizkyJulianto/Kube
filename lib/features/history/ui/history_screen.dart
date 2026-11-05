import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import 'widgets/history_summary_card.dart';
import 'widgets/transaction_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Bulan Ini', 'November', 'Desember'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black100),
          onPressed: () {},
        ),
        title: const Text(
          'Riwayat Pembelian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black100),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Semua transaksi pasokan es kristal lunas',
              style: TextStyle(fontSize: 13, color: AppColors.black50),
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _filters.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildFilterChip(
                      title: _filters[index],
                      isSelected: _selectedFilterIndex == index,
                      onTap: () => setState(() => _selectedFilterIndex = index),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary Card (Diambil dari widget terpisah)
            const HistorySummaryCard(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Daftar Transaksi Selesai', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black100)),
                Text('3 Pesanan Terbaru', style: TextStyle(fontSize: 12, color: AppColors.black50)),
              ],
            ),
            const SizedBox(height: 12),

            // Memanggil Transaction Card dengan Data Dinamis
            const TransactionCard(
              orderId: 'ORD-8821',
              date: '27 Okt, 08:15',
              productName: '10 Sak Es Kristal Tube',
              productDetail: '100 kg Paket Event Weekend',
              price: '150.000',
              truckId: 'Truk #L - 02',
            ),
            const SizedBox(height: 12),
            const TransactionCard(
              orderId: 'ORD-8820',
              date: '25 Okt, 14:30',
              productName: '5 Sak Gourmet Block Ice',
              productDetail: '50 kg Kebutuhan Reguler',
              price: '175.000',
              truckId: 'Truk #L - 04',
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFilterChip({required String title, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cerulean : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.cerulean : AppColors.alto),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.white : AppColors.black50,
          ),
        ),
      ),
    );
  }
}