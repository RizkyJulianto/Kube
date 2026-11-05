import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  
  int _deliverySchedule = 0;


  int _qtyTube = 10;
  int _qtyCrushed = 0;
  int _qtyBlock = 0;


  String _selectedPayment = 'QRIS Instan';

  int get _totalPrice =>
      (_qtyTube * 15000) + (_qtyCrushed * 25000) + (_qtyBlock * 35000);
  int get _totalBag => _qtyTube + _qtyCrushed + _qtyBlock;

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
        title: Text(
          'Pesanan Baru',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black100,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Pilihan Jadwal Pengiriman
            const Text(
              'PILIHAN JADWAL PENGIRIMAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildScheduleTab(
                    title: '⚡ Kirim Sekarang',
                    isSelected: _deliverySchedule == 0,
                    onTap: () => setState(() => _deliverySchedule = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildScheduleTab(
                    title: '📅 Jadwalkan Harian',
                    isSelected: _deliverySchedule == 1,
                    onTap: () => setState(() => _deliverySchedule = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            
            const Text(
              'ALAMAT & PEMESAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.cerulean, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Kopi Kenangan - Cabang Purwokerto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black100,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Jl. HR Bunyamin No. 108, Purwokerto Utara',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.black50,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.black50, size: 20),
                    ],
                  ),
                  const Divider(height: 20, thickness: 0.8, color: AppColors.alto),
                  Row(
                    children: const [
                      Icon(Icons.person_outline_rounded, color: AppColors.cerulean, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Pemesan: ',
                        style: TextStyle(fontSize: 12, color: AppColors.black50),
                      ),
                      Text(
                        'Sofyan Khoiron (Barista / Kasir)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Katalog Es Batu Kristal (Sesuai Figma)
            const Text(
              'KATALOG ES BATU KRISTAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            _buildProductCard(
              title: 'Ice Tube (10 Kg)',
              subtitle: 'Bening, Lubang presisi',
              price: '15.000',
              quantity: _qtyTube,
              onDecrement: () {
                if (_qtyTube > 0) setState(() => _qtyTube--);
              },
              onIncrement: () => setState(() => _qtyTube++),
            ),
            const SizedBox(height: 12),
            _buildProductCard(
              title: 'Crushed Ice (15 Kg)',
              subtitle: 'Tekstur Serut Mocktail',
              price: '25.000',
              quantity: _qtyCrushed,
              onDecrement: () {
                if (_qtyCrushed > 0) setState(() => _qtyCrushed--);
              },
              onIncrement: () => setState(() => _qtyCrushed++),
            ),
            const SizedBox(height: 12),
            _buildProductCard(
              title: 'Gourmet Block Ice',
              subtitle: 'Melting Artisan Coffee',
              price: '35.000',
              quantity: _qtyBlock,
              onDecrement: () {
                if (_qtyBlock > 0) setState(() => _qtyBlock--);
              },
              onIncrement: () => setState(() => _qtyBlock++),
            ),
            const SizedBox(height: 20),

            // 4. Metode Pembayaran
            const Text(
              'METODE PEMBAYARAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: AppColors.cerulean, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedPayment,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _selectedPayment,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.cerulean),
                    items: ['QRIS Instan', 'Transfer Bank', 'Tunai saat Terima']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPayment = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Catatan Pengiriman
            const Text(
              'CATATAN PENGIRIMAN (OPSIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Misal: Taruh di dalam freezer bagian belakang kafe',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.black50),
                fillColor: AppColors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.alto),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.alto),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cerulean),
                ),
              ),
            ),
          ],
        ),
      ),

      
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL PESANAN ($_totalBag Sak)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black50,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp. ${_totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _totalBag > 0 ? AppColors.cerulean : AppColors.alto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: _totalBag > 0 ? () {} : null,
                    child: const Text(
                      'Pesan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomBottomNav(currentIndex: 1),
        ],
      ),
    );
  }

  // Helper Tab Jadwal
  Widget _buildScheduleTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cerulean : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cerulean : AppColors.cerulean.withOpacity(0.5),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.white : AppColors.cerulean,
            ),
          ),
        ),
      ),
    );
  }

  // Helper Item Kartu Produk
  Widget _buildProductCard({
    required String title,
    required String subtitle,
    required String price,
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black100,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.black50,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Rp. $price ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cerulean,
                        ),
                      ),
                      const TextSpan(
                        text: '/ sak',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.black50,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Counter UI (Sesuai Figma)
          Row(
            children: [
              InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.pattensBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove, size: 16, color: AppColors.black100),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$quantity',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black100,
                  ),
                ),
              ),
              InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cerulean,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 16, color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}