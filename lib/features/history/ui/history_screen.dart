import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../order/ui/order_summary_screen.dart';
import '../../profile/service/profile_service.dart';
import '../service/history_service.dart';
import 'widgets/history_summary_card.dart';
import 'widgets/transaction_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Semua',
    'Bulan Ini',
    'Belum Lunas',
    'Selesai',
  ];

  bool _isLoading = true;
  String? _errorMessage;
  List _allOrders = [];
  String _ordererName = 'Mitra Kube';

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await HistoryService.getMitraOrderHistory();
      String userName = _ordererName;
      try {
        final profile = await ProfileService.getMitraProfile();
        final u = (profile['user'] as Map?) ?? {};
        if ((u['name'] ?? '').toString().trim().isNotEmpty) {
          userName = u['name'].toString().trim();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _ordererName = userName;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat riwayat pesanan: $e';
        _isLoading = false;
      });
    }
  }

  List get _filteredOrders {
    final now = DateTime.now();
    switch (_selectedFilterIndex) {
      case 1: // Bulan Ini
        return _allOrders.where((o) {
          final rawDate = o['created_at']?.toString();
          final dt =
              rawDate != null ? DateTime.tryParse(rawDate)?.toLocal() : null;
          if (dt == null) return false;
          return dt.year == now.year && dt.month == now.month;
        }).toList();
      case 2: // Belum Lunas (unpaid / waiting_verification)
        return _allOrders.where((o) {
          final payStatus =
              (o['payment_status'] ?? '').toString().toLowerCase();
          return payStatus == 'unpaid' || payStatus == 'waiting_verification';
        }).toList();
      case 3: // Selesai
        return _allOrders.where((o) {
          final ordStatus = (o['order_status'] ?? '').toString().toLowerCase();
          return ordStatus == 'completed' || ordStatus == 'delivered';
        }).toList();
      default: // Semua
        return _allOrders;
    }
  }

  String _formatRupiah(num amount) {
    final intVal = amount.round();
    return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '-';
    final dt = DateTime.tryParse(isoStr)?.toLocal();
    if (dt == null) return isoStr;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final mon = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day $mon ${dt.year}, $hour:$min';
  }

  String _buildProductSummary(List<dynamic> items) {
    if (items.isEmpty) return 'Pesanan Es Kristal';
    final parts = items.map((item) {
      final qty = ((item['quantity'] as num?) ?? 0).toInt();
      final name = (item['product_name'] ?? 'Es Kristal').toString();
      return '$qty Sak $name';
    }).toList();
    return parts.join(', ');
  }

  int _calculateTotalSacks(List orders) {
    int total = 0;
    for (final order in orders) {
      final items = (order['items'] as List?) ?? [];
      for (final item in items) {
        total += ((item['quantity'] as num?) ?? 0).toInt();
      }
    }
    return total;
  }

  void _openOrderReceipt(Map<String, dynamic> order) {
    final isScheduled =
        (order['delivery_type'] ?? '').toString().toLowerCase() == 'scheduled';
    final schedTime = (order['scheduled_time'] ?? '').toString().trim();
    final scheduleLabel = isScheduled
        ? 'Terjadwal${schedTime.isNotEmpty ? " ($schedTime)" : ""}'
        : 'Kirim Sekarang';

    final rawItems = (order['items'] as List?) ?? [];
    final mappedItems = rawItems.map((it) {
      return {
        'name': it['product_name'] ?? 'Es Kristal',
        'quantity': it['quantity'] ?? 0,
        'price_per_unit': it['price_per_unit'] ?? 0,
        'subtotal': it['subtotal'] ?? 0,
      };
    }).toList();

    final payMethod = Map<String, dynamic>.from(
      (order['payment_method'] as Map?) ?? {'name': 'Tunai', 'code': 'COD'},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          orderId: order['order_code'] ?? order['id'],
          dbOrderId: order['id'],
          outletName: 'Alamat Pengiriman',
          outletAddress: (order['delivery_address'] ?? '-').toString(),
          ordererInfo: _ordererName,
          deliveryScheduleLabel: scheduleLabel,
          paymentMethod: payMethod,
          orderedItems: mappedItems,
          totalAmount: (order['total_amount'] as num?) ?? 0,
          notes: order['notes']?.toString(),
          initialPaymentStatus: order['payment_status']?.toString(),
          initialPaymentProofUrl: order['payment_proof_url']?.toString(),
        ),
      ),
    ).then((_) => _loadHistoryData());
  }

  void _showRecapDialog(
    List orders,
    num totalSpending,
    int totalSacks,
  ) {
    final filterName = _filters[_selectedFilterIndex];
    final buffer = StringBuffer();
    buffer.writeln('REKAP TRANSAKSI KUBE ($filterName)');
    buffer.writeln('Mitra: $_ordererName');
    buffer.writeln('Total Pesanan: ${orders.length} transaksi ($totalSacks Sak)');
    buffer.writeln('Total Nominal: Rp. ${_formatRupiah(totalSpending)}');
    buffer.writeln('-----------------------------------');
    for (final o in orders) {
      final code = o['order_code'] ?? '#${o['id']}';
      final amt = _formatRupiah((o['total_amount'] as num?) ?? 0);
      final status = (o['payment_status'] ?? 'unpaid').toString().toUpperCase();
      buffer.writeln('• $code | Rp. $amt [$status]');
    }

    final recapText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rekap Transaksi ($filterName)',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            recapText,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cerulean,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: recapText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rekap transaksi berhasil disalin!'),
                  backgroundColor: AppColors.cerulean,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Salin Rekap',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _filteredOrders;
    final num totalSpending = visibleOrders.fold<num>(
      0,
      (sum, item) => sum + ((item['total_amount'] as num?) ?? 0),
    );
    final int totalSacks = _calculateTotalSacks(visibleOrders);
    final int unpaidCount = visibleOrders.where((o) {
      final st = (o['payment_status'] ?? '').toString().toLowerCase();
      return st != 'paid';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Riwayat Pembelian',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black100,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cerulean,
          onRefresh: _loadHistoryData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Pantau seluruh riwayat pasokan & nota pembayaran es kristal',
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
                        onTap: () =>
                            setState(() => _selectedFilterIndex = index),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Summary Card Dinamis
              HistorySummaryCard(
                filterLabel: _filters[_selectedFilterIndex],
                totalSpending: totalSpending,
                totalSacks: totalSacks,
                unpaidCount: unpaidCount,
                onExportTap: () => _showRecapDialog(
                  visibleOrders,
                  totalSpending,
                  totalSacks,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Transaksi (${_filters[_selectedFilterIndex]})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black100,
                    ),
                  ),
                  Text(
                    '${visibleOrders.length} Pesanan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.black50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.cerulean),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loadHistoryData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              else if (visibleOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.alto),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 44,
                        color: AppColors.black50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada riwayat pesanan pada filter ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black70,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pesanan es kristal yang kamu buat akan otomatis muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.black50,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...visibleOrders.map((order) {
                  final items = (order['items'] as List?) ?? [];
                  final payMethod = (order['payment_method'] as Map?) ?? {};
                  final isScheduled =
                      (order['delivery_type'] ?? '').toString().toLowerCase() ==
                          'scheduled';
                  final schedTime =
                      (order['scheduled_time'] ?? '').toString().trim();
                  final address =
                      (order['delivery_address'] ?? '-').toString().trim();

                  final detailSubtitle = isScheduled && schedTime.isNotEmpty
                      ? '$schedTime • $address'
                      : address;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionCard(
                      orderCode: (order['order_code'] ?? '#${order['id']}')
                          .toString(),
                      date: _formatDate(order['created_at']?.toString()),
                      productSummary: _buildProductSummary(items),
                      deliveryDetail: detailSubtitle,
                      price:
                          _formatRupiah((order['total_amount'] as num?) ?? 0),
                      paymentMethodName:
                          (payMethod['name'] ?? 'Tunai').toString(),
                      orderStatus:
                          (order['order_status'] ?? 'pending').toString(),
                      paymentStatus:
                          (order['payment_status'] ?? 'unpaid').toString(),
                      isScheduled: isScheduled,
                      onDetailTap: () => _openOrderReceipt(order),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFilterChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cerulean : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cerulean : AppColors.alto,
          ),
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