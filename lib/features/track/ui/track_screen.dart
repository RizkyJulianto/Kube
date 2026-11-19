import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../chat/ui/order_chat_screen.dart';
import '../../order/ui/order_screen.dart';
import '../service/tracking_service.dart';

class TrackingScreen extends StatefulWidget {
  final dynamic initialOrderId;

  const TrackingScreen({
    super.key,
    this.initialOrderId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  List _orders = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  RealtimeChannel? _trackingChannel;

  @override
  void initState() {
    super.initState();
    _loadTrackingOrders();
    _subscribeRealtimeUpdates();
  }

  void _subscribeRealtimeUpdates() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _trackingChannel = Supabase.instance.client
        .channel('consumer_tracking_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'consumer_id',
            value: userId,
          ),
          callback: (_) {
            if (mounted) _loadTrackingOrders(silent: true);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deliveries',
          callback: (_) {
            if (mounted) _loadTrackingOrders(silent: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_trackingChannel != null) {
      Supabase.instance.client.removeChannel(_trackingChannel!);
    }
    super.dispose();
  }

  Future<void> _loadTrackingOrders({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await TrackingService.getTrackableOrders();
      if (!mounted) return;

      int targetIdx = 0;
      if (widget.initialOrderId != null && list.isNotEmpty) {
        final foundIdx = list.indexWhere(
          (o) =>
              o['id'].toString() == widget.initialOrderId.toString() ||
              o['order_code'].toString() == widget.initialOrderId.toString(),
        );
        if (foundIdx != -1) {
          targetIdx = foundIdx;
        }
      } else if (_orders.isNotEmpty && list.isNotEmpty) {
        final prevId = _orders[_selectedIndex]['id'];
        final keepIdx = list.indexWhere((o) => o['id'] == prevId);
        if (keepIdx != -1) targetIdx = keepIdx;
      }

      setState(() {
        _orders = list;
        _selectedIndex = targetIdx;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data pelacakan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _mapStatusToStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0; // Dibuat
      case 'processing':
        return 1; // Disiapkan
      case 'delivering':
        return 2; // Dikirim
      case 'completed':
        return 3; // Diterima
      case 'cancelled':
        return -1; // Dibatalkan
      default:
        return 0;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Dibuat';
      case 'processing':
        return 'Disiapkan';
      case 'delivering':
        return 'Dikirim';
      case 'completed':
        return 'Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatRupiah(num amount) {
    final intVal = amount.round();
    return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatWeightKg(num weight) {
    return weight % 1 == 0 ? '${weight.toInt()} Kg' : '$weight Kg';
  }

  String _formatDateTime(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hh:$mm WIB';
    } catch (_) {
      return isoStr;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'KR';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleConfirmReceived(Map<String, dynamic> order) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await TrackingService.confirmOrderReceived(order['id']);
      await _loadTrackingOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Pesanan telah dikonfirmasi diterima.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengonfirmasi pesanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.black100,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: Text(
          'Lacak Pengiriman',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black100,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Muat Ulang Status',
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.cerulean,
              size: 22,
            ),
            onPressed: () => _loadTrackingOrders(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cerulean),
              )
            : _orders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppColors.cerulean,
                    onRefresh: () => _loadTrackingOrders(),
                    child: _buildTrackingContent(_orders[_selectedIndex]),
                  ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.pattensBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 44,
                color: AppColors.cerulean,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesanan Dilacak',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black100,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buat pesanan es kristal terlebih dahulu untuk memantau status pengirimannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.black50),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cerulean,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderScreen()),
                );
              },
              icon: const Icon(Icons.add_shopping_cart_rounded,
                  color: AppColors.white, size: 18),
              label: const Text(
                'Pesan Es Sekarang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent(Map<String, dynamic> order) {
    final int orderIdInt = int.tryParse(order['id'].toString()) ?? 0;
    final orderCode = (order['order_code'] ?? '#${order['id']}').toString();
    final orderStatus = (order['order_status'] ?? 'pending').toString();
    final paymentStatus = (order['payment_status'] ?? 'unpaid').toString();
    final currentStep = _mapStatusToStep(orderStatus);
    final isCancelled = orderStatus.toLowerCase() == 'cancelled';
    final isOrderClosed = currentStep == 3 || isCancelled;

    final deliveryAddress =
        (order['delivery_address'] ?? 'Alamat tidak tersedia').toString();
    final deliveryType = (order['delivery_type'] ?? 'instant').toString();
    final scheduledTime = (order['scheduled_time'] ?? '').toString();
    final notes = (order['notes'] ?? '').toString();
    final totalAmount = (order['total_amount'] as num?) ?? 0;

    final List items = (order['items'] as List?)?.cast() ?? [];

    final Map<String, dynamic>? courier =
        order['courier'] as Map<String, dynamic>?;
    final List logs = (order['logs'] as List?)?.cast() ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 0. Daftar Semua Pesanan (Pemantauan Terpisah Per-Transaksi / Per-Produk)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DAFTAR PESANAN KAMU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.black50,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Total ${_orders.length} Pesanan',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.cerulean,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final itemOrder = _orders[idx];
              final isSelected = idx == _selectedIndex;
              final code =
                  (itemOrder['order_code'] ?? '#${itemOrder['id']}').toString();
              final st = (itemOrder['order_status'] ?? 'pending').toString();
              final orderItems = (itemOrder['items'] as List?) ?? [];

              final productSummary = orderItems.isEmpty
                  ? 'Pesanan Es Kristal'
                  : orderItems.map((it) {
                      final p = it['products'] as Map?;
                      final pName = (p?['name'] ?? 'Es Kristal').toString();
                      final qty = it['quantity'] ?? 0;
                      return '$pName ($qty Sak)';
                    }).join(', ');

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = idx),
                child: Container(
                  width: 235,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cerulean : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.cerulean : AppColors.alto,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.black100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.white.withValues(alpha: 0.22)
                                  : _getStatusBadgeColor(st)
                                      .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getStatusLabel(st),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.white
                                    : _getStatusBadgeColor(st),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        productSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.white.withValues(alpha: 0.92)
                              : AppColors.black70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // 1. Card Step Timeline Progress
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.alto),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STATUS PESANAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black50,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: orderCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode pesanan disalin'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          orderCode,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cerulean,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: AppColors.cerulean,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timeline Step Indicator (4 Tahap)
              Row(
                children: [
                  _buildStepNode(
                      0, currentStep, 'Dibuat', Icons.receipt_long_outlined),
                  _buildStepLine(0, currentStep),
                  _buildStepNode(
                      1, currentStep, 'Disiapkan', Icons.inventory_2_outlined),
                  _buildStepLine(1, currentStep),
                  _buildStepNode(
                      2, currentStep, 'Dikirim', Icons.local_shipping_outlined),
                  _buildStepLine(2, currentStep),
                  _buildStepNode(3, currentStep, 'Diterima',
                      Icons.check_circle_outline_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Banner Status Pengiriman Utama (Dinamis per step)
        _buildStatusBanner(currentStep, paymentStatus, isCancelled, courier),
        const SizedBox(height: 20),

        // 3. Info Driver & Kontak (Langsung muncul begitu kurir ditugaskan, termasuk saat status Disiapkan)
        if (!isCancelled) ...[
          const Text(
            'INFORMASI DRIVER & BANTUAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.black50,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (courier != null)
            _buildDriverCard(
              courier: courier,
              orderId: orderIdInt,
              orderCode: orderCode,
              isClosed: isOrderClosed,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.pattensBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: AppColors.cerulean,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menunggu Penugasan Kurir',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStep == 0
                              ? 'Pesanan sedang menunggu konfirmasi pabrik.'
                              : 'Admin sedang menyiapkan armada pengantar untuk pesanan ini.',
                          style: const TextStyle(
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
          const SizedBox(height: 10),

          // Tombol In-App Chat Admin Kube (Tersedia per pesanan)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.cerulean),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderChatScreen(
                      orderId: orderIdInt,
                      orderCode: orderCode,
                      roomType: 'consumer_admin',
                      recipientName: 'Admin Kube',
                      recipientSubtitle: 'Layanan Pelanggan & Konfirmasi',
                      courierUserId: courier?['id']?.toString(),
                      isOrderClosed: isOrderClosed,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.cerulean,
                size: 19,
              ),
              label: const Text(
                'Chat Admin Kube',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cerulean,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 4. Detail Rincian Barang & Alamat Tujuan
        const Text(
          'RINCIAN PENGIRIMAN & PRODUK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.black50,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.alto),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.cerulean,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deliveryType == 'scheduled'
                              ? 'Pengiriman Terjadwal ($scheduledTime)'
                              : 'Pengiriman Instan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deliveryAddress,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.black50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.alto),

              // Daftar Item Produk & Berat Muatan (1 sak = 1 Kg)
              if (items.isEmpty)
                const Text(
                  'Rincian produk tidak tersedia.',
                  style: TextStyle(fontSize: 12, color: AppColors.black50),
                )
              else
                ...items.map((item) {
                  final productMap = item['products'] as Map?;
                  final productName =
                      (productMap?['name'] ?? 'Es Kristal').toString();
                  final qty = (item['quantity'] as num?) ?? 0;
                  final unitWeight = (productMap?['unit_weight_kg'] ??
                          productMap?['unit_weight'] ??
                          item['unit_weight'] ??
                          1) as num;
                  final totalWeightKg = qty * unitWeight;
                  final subtotal = (item['subtotal'] as num?) ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: AppColors.cerulean,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$productName ($qty Sak • ${_formatWeightKg(totalWeightKg)})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black100,
                            ),
                          ),
                        ),
                        Text(
                          'Rp ${_formatRupiah(subtotal)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const Divider(height: 16, color: AppColors.alto),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black70,
                    ),
                  ),
                  Text(
                    'Rp ${_formatRupiah(totalAmount)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cerulean,
                    ),
                  ),
                ],
              ),

              if (notes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Catatan: $notes',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.black70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Riwayat Log Perjalanan (jika tersedia di delivery_logs)
        if (logs.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'RIWAYAT PERJALANAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.black50,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.alto),
            ),
            child: Column(
              children: logs.map((lg) {
                final desc = (lg['notes'] ??
                        lg['description'] ??
                        lg['status'] ??
                        'Pembaruan status pengiriman')
                    .toString();
                final time = _formatDateTime(lg['created_at']?.toString());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.cerulean,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black100,
                              ),
                            ),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.black50,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // 5. TOMBOL CALL-TO-ACTION (CTA) DINAMIS
        if (currentStep == 2) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _handleConfirmReceived(order),
              icon: _isUpdatingStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
              label: const Text(
                'Konfirmasi Pesanan Diterima',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ] else if (currentStep == 3 || isCancelled) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cerulean),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderScreen()),
                );
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.cerulean,
                size: 20,
              ),
              label: const Text(
                'Pesan Lagi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cerulean,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Color _getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF059669);
      case 'delivering':
        return AppColors.cerulean;
      case 'processing':
        return Colors.orange[800]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return AppColors.black70;
    }
  }

  Widget _buildStatusBanner(
    int currentStep,
    String paymentStatus,
    bool isCancelled,
    Map<String, dynamic>? courier,
  ) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesanan Dibatalkan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pesanan ini telah dibatalkan. Silakan buat pesanan baru jika diperlukan.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bool isCompleted = currentStep == 3;
    String title;
    String subtitle;
    IconData icon;

    switch (currentStep) {
      case 0:
        title = 'Pesanan Berhasil Dibuat';
        subtitle = paymentStatus == 'unpaid'
            ? 'Menunggu pembayaran / konfirmasi admin Kube.'
            : 'Pesanan masuk antrean persiapan pabrik.';
        icon = Icons.receipt_long_rounded;
        break;
      case 1:
        title = 'Es Kristal Sedang Disiapkan';
        subtitle = courier != null
            ? 'Kurir ${courier['name']} telah ditugaskan & bersiap mengantar.'
            : 'Tim produksi sedang menyiapkan muatan & armada.';
        icon = Icons.inventory_2_rounded;
        break;
      case 2:
        title = 'Kurir sedang dalam perjalanan';
        subtitle = 'Armada Kube sedang menuju lokasi pengiriman kamu.';
        icon = Icons.local_shipping_rounded;
        break;
      case 3:
      default:
        title = 'Pesanan Sudah Diterima';
        subtitle = 'Es batu kristal sudah diterima di lokasi tujuan.';
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFD1FAE5) : AppColors.pattensBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981)
              : AppColors.cerulean.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isCompleted ? const Color(0xFF10B981) : AppColors.cerulean,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black100,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF059669)
                        : AppColors.cerulean,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard({
    required Map<String, dynamic> courier,
    required int orderId,
    required String orderCode,
    required bool isClosed,
  }) {
    final driverName = (courier['name'] ?? 'Kurir Kube').toString();
    final vehicle = (courier['vehicle_type'] ?? 'Armada Kube').toString();
    final plate = (courier['license_plate'] ?? '').toString();
    final vehicleLabel = plate.isNotEmpty ? '$vehicle - $plate' : vehicle;
    final phone = (courier['phone'] ?? '').toString();
    final courierUserId = courier['id']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.alto),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.cerulean,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(driverName),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: AppColors.cerulean, size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  vehicleLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.black50),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty) ...[
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nomor kurir ($phone) disalin'),
                    backgroundColor: AppColors.cerulean,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cerulean),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.cerulean,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Tombol In-App Chat Kurir (menggunakan room_type: 'order_chat')
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderChatScreen(
                    orderId: orderId,
                    orderCode: orderCode,
                    roomType: 'order_chat',
                    recipientName: driverName,
                    recipientSubtitle: vehicleLabel,
                    courierUserId: courierUserId,
                    isOrderClosed: isClosed,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(
      int index, int currentStep, String label, IconData icon) {
    final bool isCompleted = currentStep >= 0 && index <= currentStep;
    final bool isCurrent = currentStep >= 0 && index == currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.cerulean : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? AppColors.cerulean : AppColors.alto,
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.cerulean.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted ? AppColors.white : AppColors.black50,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? AppColors.black100 : AppColors.black50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int index, int currentStep) {
    final bool isCompleted = currentStep >= 0 && index < currentStep;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isCompleted ? AppColors.cerulean : AppColors.alto,
    );
  }
}