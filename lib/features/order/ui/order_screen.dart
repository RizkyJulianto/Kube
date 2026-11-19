import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../profile/service/profile_service.dart';
import '../service/order_service.dart';
import 'address_form_sheet.dart';
import 'order_summary_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // Jadwal pengiriman
  int _deliverySchedule = 0; // 0 = Kirim Sekarang (instant), 1 = Jadwalkan Harian (scheduled)
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
  String _scheduleFrequency = 'Setiap Hari';
  int _scheduleDurationDays = 7;

  final List<String> _frequencyOptions = [
    'Setiap Hari',
    'Senin - Jumat',
    'Akhir Pekan (Sabtu - Minggu)',
    '1x Jadwal Besok',
  ];
  final List<int> _durationOptions = [7, 14, 30];

  final TextEditingController _notesController = TextEditingController();

  // Data Pemesan & Multi-Alamat
  String _ordererInfo = 'Memuat pemesan...';
  String _selectedAddressLabel = 'Alamat Utama (Profil)';
  String _selectedAddressText = 'Memuat alamat pengiriman...';
  String? _selectedAddressId;
  List _savedAddresses = [];

  List _products = [];
  List _paymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;
  final Map<dynamic, int> _quantities = {};
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  bool get _hasValidAddress {
    return _savedAddresses.isNotEmpty &&
        _selectedAddressText.trim().isNotEmpty &&
        !_selectedAddressText.startsWith('Alamat belum diatur') &&
        !_selectedAddressText.startsWith('Memuat alamat') &&
        !_selectedAddressText.startsWith('Gagal memuat');
  }

  /// Cek apakah masih ada minimal 1 produk yang memiliki stok > 0
  bool get _hasAnyStockAvailable {
    for (final p in _products) {
      final stock = (p['stock'] as num?)?.toInt() ?? 0;
      if (stock > 0) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    await Future.wait([
      _loadUserAndAddresses(),
      _loadProducts(),
      _loadPaymentMethods(),
    ]);
    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadUserAndAddresses() async {
    String name = 'Mitra Kube';
    String cafeName = '';
    String primaryAddress = '';
    double? primaryLat;
    double? primaryLng;
    List extraAddresses = [];

    try {
      final profileData = await ProfileService.getMitraProfile();
      final user = (profileData['user'] as Map?) ?? {};
      final consumer = (profileData['consumer'] as Map?) ?? {};

      name = (user['name'] ?? 'Mitra Kube').toString().trim();
      cafeName = (consumer['cafe_name'] ?? '').toString().trim();
      primaryAddress = (consumer['address'] ?? '').toString().trim();
      primaryLat = (consumer['latitude'] as num?)?.toDouble();
      primaryLng = (consumer['longitude'] as num?)?.toDouble();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedAddressLabel = 'Mitra Kube';
        _selectedAddressText = 'Gagal memuat profil: $e';
        _ordererInfo = 'Pengguna Aktif';
      });
      return;
    }

    try {
      extraAddresses = await OrderService.getConsumerAddresses();
    } catch (_) {
      extraAddresses = [];
    }

    final List combined = [];

    // Cari apakah alamat utama profil juga tersimpan di tabel consumer_addresses
    Map<String, dynamic>? matchingPrimaryRow;
    if (primaryAddress.isNotEmpty) {
      for (final item in extraAddresses) {
        if ((item['address'] ?? '').toString().trim() == primaryAddress) {
          matchingPrimaryRow = item;
          break;
        }
      }

      final baseLabel = matchingPrimaryRow != null
          ? (matchingPrimaryRow['label'] ?? cafeName).toString().trim()
          : (cafeName.isNotEmpty ? cafeName : 'Outlet Utama');

      combined.add({
        'id': matchingPrimaryRow?['id']?.toString(),
        'raw_label': baseLabel,
        'label': '$baseLabel (Alamat Utama)',
        'address': primaryAddress,
        'latitude': matchingPrimaryRow?['latitude'] ?? primaryLat,
        'longitude': matchingPrimaryRow?['longitude'] ?? primaryLng,
        'is_primary': true,
      });
    }

    for (final item in extraAddresses) {
      if (matchingPrimaryRow != null &&
          item['id']?.toString() == matchingPrimaryRow['id']?.toString()) {
        continue;
      }
      final itemAddress = (item['address'] ?? '').toString().trim();
      if (primaryAddress.isNotEmpty && itemAddress == primaryAddress) {
        continue;
      }
      final lbl = (item['label'] ?? 'Alamat Tambahan').toString().trim();
      combined.add({
        'id': item['id']?.toString(),
        'raw_label': lbl,
        'label': lbl,
        'address': itemAddress,
        'latitude': item['latitude'],
        'longitude': item['longitude'],
        'is_primary': false,
      });
    }

    if (!mounted) return;
    setState(() {
      _ordererInfo = name;
      _savedAddresses = combined;

      if (combined.isNotEmpty) {
        final existingIndex = combined.indexWhere(
          (e) =>
              e['id'] == _selectedAddressId &&
              e['address'] == _selectedAddressText,
        );
        final chosen =
            existingIndex != -1 ? combined[existingIndex] : combined.first;
        _selectedAddressId = chosen['id'] as String?;
        _selectedAddressLabel = chosen['label'].toString();
        _selectedAddressText = chosen['address'].toString();
      } else {
        _selectedAddressId = null;
        _selectedAddressLabel = cafeName.isNotEmpty ? cafeName : name;
        _selectedAddressText =
            'Alamat belum diatur (Ketuk untuk menambah alamat)';
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      final list = await OrderService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
        for (final p in _products) {
          final id = p['id'];
          final stock = (p['stock'] as num?)?.toInt() ?? 0;
          final currentQty = _quantities[id] ?? 0;
          if (currentQty > stock) {
            _quantities[id] = stock > 0 ? stock : 0;
          } else {
            _quantities.putIfAbsent(id, () => 0);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final list = await OrderService.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = list;
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethod =
              Map<String, dynamic>.from(_paymentMethods.first);
        }
      });
    } catch (_) {}
  }

  /// Dialog input langsung jumlah sak (misal ketik 20 langsung lompat ke 20)
  void _showDirectQuantityDialog({
    required dynamic productId,
    required String productName,
    required int stock,
    required int currentQty,
  }) {
    if (stock <= 0) return;
    final qtyCtrl = TextEditingController(
      text: currentQty > 0 ? currentQty.toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Jumlah Pesanan ($productName)',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.black100,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan jumlah sak yang diinginkan (maks. $stock sak):',
                style: const TextStyle(fontSize: 12, color: AppColors.black70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cerulean,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: 20',
                  suffixText: 'sak',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cerulean),
                  ),
                ),
                onSubmitted: (_) {
                  final parsed = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final clamped = parsed.clamp(0, stock);
                  setState(() => _quantities[productId] = clamped);
                  Navigator.pop(dialogCtx);
                  if (parsed > stock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Jumlah disesuaikan ke stok maksimal ($stock sak).',
                        ),
                        backgroundColor: Colors.orange[800],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.black50),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cerulean,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final parsed = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                final clamped = parsed.clamp(0, stock);
                setState(() => _quantities[productId] = clamped);
                Navigator.pop(dialogCtx);
                if (parsed > stock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Jumlah disesuaikan ke stok maksimal ($stock sak).',
                      ),
                      backgroundColor: Colors.orange[800],
                    ),
                  );
                }
              },
              child: const Text(
                'Terapkan',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddressForm({
    Map<String, dynamic>? existingAddress,
    bool isFirstAddress = false,
  }) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormSheet(
        existingAddress: existingAddress,
        isFirstAddress: isFirstAddress,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAddressId = result['id']?.toString();
        _selectedAddressLabel = result['label'].toString();
        _selectedAddressText = result['address'].toString();
      });
      await _loadUserAndAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingAddress != null
                ? 'Alamat berhasil diperbarui!'
                : 'Alamat baru berhasil disimpan & dijadikan alamat utama!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAddress(Map<String, dynamic> item) async {
    final bool isPrimary = item['is_primary'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Alamat?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPrimary
              ? 'Alamat ini adalah alamat utama di Profil kamu. Jika dihapus, alamat di Profil juga akan otomatis diperbarui atau dikosongkan. Lanjutkan?'
              : 'Alamat "${item['label']}" akan dihapus dari daftar alamat tersimpan. Lanjutkan?',
          style: const TextStyle(fontSize: 13, color: AppColors.black70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.black50),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await OrderService.deleteConsumerAddress(
        addressId: item['id']?.toString(),
        isPrimaryProfile: isPrimary,
      );
      await _loadUserAndAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus alamat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddressPickerSheet() {
    if (_savedAddresses.isEmpty) {
      _openAddressForm(isFirstAddress: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.alto,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih atau Kelola Alamat',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black100,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ketuk alamat untuk memilih, atau ubah/hapus alamat yang ada.',
                  style: TextStyle(fontSize: 12, color: AppColors.black50),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _savedAddresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = _savedAddresses[index];
                      final isSelected =
                          item['id'] == _selectedAddressId &&
                          item['address'] == _selectedAddressText;
                      final isPrimary = item['is_primary'] == true;
                      final hasCoords =
                          item['latitude'] != null && item['longitude'] != null;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAddressId = item['id'] as String?;
                            _selectedAddressLabel = item['label'].toString();
                            _selectedAddressText = item['address'].toString();
                          });
                          Navigator.pop(sheetCtx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.pattensBlue.withValues(alpha: 0.45)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.cerulean
                                  : AppColors.alto,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  isPrimary
                                      ? Icons.store_rounded
                                      : Icons.location_on_rounded,
                                  color: AppColors.cerulean,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item['label'].toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.black100,
                                            ),
                                          ),
                                        ),
                                        if (hasCoords) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Titik GPS',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['address'].toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.black70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Aksi Ubah & Hapus
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Ubah Alamat',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppColors.cerulean,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(sheetCtx);
                                      _openAddressForm(
                                        existingAddress: item,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus Alamat',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(sheetCtx);
                                      _confirmDeleteAddress(item);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cerulean),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _openAddressForm(isFirstAddress: false);
                    },
                    icon: const Icon(
                      Icons.add_location_alt_rounded,
                      color: AppColors.cerulean,
                      size: 20,
                    ),
                    label: const Text(
                      'Tambah Alamat Baru (Titik Peta)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cerulean,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _totalBag {
    int total = 0;
    for (final qty in _quantities.values) {
      total += qty;
    }
    return total;
  }

  num get _totalPrice {
    num total = 0;
    for (final p in _products) {
      final id = p['id'];
      final qty = _quantities[id] ?? 0;
      final price = (p['price'] as num?) ?? 0;
      total += qty * price;
    }
    return total;
  }

  String _formatRupiah(num amount) {
    final intVal = amount.round();
    return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String get _formattedTimeStr =>
      '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')} WIB';

  String get _scheduledSummaryText {
    if (_scheduleFrequency == '1x Jadwal Besok') {
      return '$_formattedTimeStr • 1x Jadwal Besok';
    }
    return '$_formattedTimeStr • $_scheduleFrequency ($_scheduleDurationDays Hari)';
  }

  Future<void> _pickScheduledTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null && mounted) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _submitOrder() async {
    if (_totalBag <= 0 || _isSubmitting || !_hasAnyStockAvailable) return;

    if (!_hasValidAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi alamat pengiriman terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      _openAddressForm(isFirstAddress: true);
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final List selectedItemsPayload = [];
      final List summaryItems = [];

      for (final p in _products) {
        final id = p['id'];
        final qty = _quantities[id] ?? 0;
        final stock = (p['stock'] as num?)?.toInt() ?? 0;
        if (qty > 0) {
          if (qty > stock) {
            throw Exception(
              'Jumlah "${p['name']}" melebihi stok tersisa ($stock sak).',
            );
          }
          final price = (p['price'] as num?) ?? 0;
          final subtotal = qty * price;
          selectedItemsPayload.add({
            'product_id': id,
            'quantity': qty,
            'price_per_unit': price,
            'subtotal': subtotal,
          });
          summaryItems.add({
            'name': p['name'],
            'unit': 'sak',
            'quantity': qty,
            'price_per_unit': price,
            'subtotal': subtotal,
          });
        }
      }

      final isScheduled = _deliverySchedule == 1;
      final scheduledStr = isScheduled ? _scheduledSummaryText : null;
      final paymentMethodId = _selectedPaymentMethod!['id'] as int;
      final notesText = _notesController.text.trim();
      final orderTotal = _totalPrice;

      final createdOrder = await OrderService.createOrder(
        paymentMethodId: paymentMethodId,
        deliveryAddress: _selectedAddressText,
        deliveryAddressId: _selectedAddressId,
        deliveryType: isScheduled ? 'scheduled' : 'instant',
        scheduledTime: scheduledStr,
        totalAmount: orderTotal,
        items: selectedItemsPayload,
        notes: notesText.isEmpty ? null : notesText,
      );

      if (!mounted) return;

      final scheduleLabel =
          isScheduled ? 'Terjadwal ($scheduledStr)' : 'Kirim Sekarang';

      final selectedPaymentCopy =
          Map<String, dynamic>.from(_selectedPaymentMethod!);

      setState(() {
        for (final key in _quantities.keys) {
          _quantities[key] = 0;
        }
        _notesController.clear();
      });

      await _loadProducts();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSummaryScreen(
            orderId: createdOrder['order_code'] ?? createdOrder['id'],
            dbOrderId: createdOrder['id'],
            outletName: _selectedAddressLabel,
            outletAddress: _selectedAddressText,
            ordererInfo: _ordererInfo,
            deliveryScheduleLabel: scheduleLabel,
            paymentMethod: selectedPaymentCopy,
            orderedItems: summaryItems,
            totalAmount: orderTotal,
            notes: notesText.isEmpty ? null : notesText,
          ),
        ),
      );
    } catch (e) {
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPaymentId = _selectedPaymentMethod?['id'];
    final currentPaymentName =
        (_selectedPaymentMethod?['name'] ?? 'Pilih Metode').toString();
    final bool needsAddress = !_isLoadingData && !_hasValidAddress;
    final bool allOutOfStock =
        !_isLoadingData && _products.isNotEmpty && !_hasAnyStockAvailable;
    final bool canOrder =
        _totalBag > 0 && !_isSubmitting && _hasAnyStockAvailable;

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
        child: RefreshIndicator(
          color: AppColors.cerulean,
          onRefresh: _loadInitialData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
              if (_deliverySchedule == 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pattensBlue.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.cerulean.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _pickScheduledTime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jam Pengiriman Rutin',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black70,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      AppColors.cerulean.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _formattedTimeStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cerulean,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 15,
                                    color: AppColors.cerulean,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pola Hari Pengiriman',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _frequencyOptions.map((freq) {
                          final active = _scheduleFrequency == freq;
                          return ChoiceChip(
                            label: Text(
                              freq,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.white
                                    : AppColors.black70,
                              ),
                            ),
                            selected: active,
                            selectedColor: AppColors.cerulean,
                            backgroundColor: AppColors.white,
                            onSelected: (_) {
                              setState(() => _scheduleFrequency = freq);
                            },
                          );
                        }).toList(),
                      ),
                      if (_scheduleFrequency != '1x Jadwal Besok') ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Durasi Langganan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: _durationOptions.map((days) {
                            final active = _scheduleDurationDays == days;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  '$days Hari',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? AppColors.white
                                        : AppColors.black70,
                                  ),
                                ),
                                selected: active,
                                selectedColor: AppColors.cerulean,
                                backgroundColor: AppColors.white,
                                onSelected: (_) {
                                  setState(
                                    () => _scheduleDurationDays = days,
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ALAMAT & PEMESAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black50,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddressPickerSheet,
                    child: Text(
                      needsAddress
                          ? '+ Isi Alamat Wajib'
                          : 'Kelola / Ubah Alamat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: needsAddress
                            ? Colors.orange[800]
                            : AppColors.cerulean,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _showAddressPickerSheet,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: needsAddress
                        ? Colors.orange.withValues(alpha: 0.04)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: needsAddress ? Colors.orange : AppColors.alto,
                      width: needsAddress ? 1.3 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            needsAddress
                                ? Icons.add_location_alt_rounded
                                : Icons.location_on_rounded,
                            color: needsAddress
                                ? Colors.orange[800]
                                : AppColors.cerulean,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAddressLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black100,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedAddressText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: needsAddress
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: needsAddress
                                        ? Colors.orange[800]
                                        : AppColors.black50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: needsAddress
                                ? Colors.orange[800]
                                : AppColors.black50,
                            size: 20,
                          ),
                        ],
                      ),
                      const Divider(
                        height: 20,
                        thickness: 0.8,
                        color: AppColors.alto,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.cerulean,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Pemesan: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.black50,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _ordererInfo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KATALOG ES BATU KRISTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black50,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!_isLoadingData && _products.isNotEmpty)
                    GestureDetector(
                      onTap: _loadProducts,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 13,
                            color: AppColors.cerulean,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Cek Stok',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cerulean,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (allOutOfStock) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Semua stok es batu kristal sedang habis. Pemesanan sementara ditutup hingga stok tersedia kembali.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_isLoadingData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.cerulean),
                  ),
                )
              else if (_products.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.alto),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada produk es kristal tersedia.',
                      style: TextStyle(fontSize: 12, color: AppColors.black50),
                    ),
                  ),
                )
              else
                ..._products.map((product) {
                  final id = product['id'];
                  final name = (product['name'] ?? 'Es Kristal').toString();
                  final desc = (product['description'] ??
                          'Kualitas higienis & tahan lama')
                      .toString();
                  final price = (product['price'] as num?) ?? 0;
                  final stock = (product['stock'] as num?)?.toInt() ?? 0;
                  final qty = _quantities[id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProductCard(
                      title: name,
                      subtitle: desc,
                      price: _formatRupiah(price),
                      unit: 'sak',
                      stock: stock,
                      quantity: qty,
                      onTapQuantity: () => _showDirectQuantityDialog(
                        productId: id,
                        productName: name,
                        stock: stock,
                        currentQty: qty,
                      ),
                      onDecrement: () {
                        if (qty > 0) {
                          setState(() => _quantities[id] = qty - 1);
                        }
                      },
                      onIncrement: () {
                        if (stock <= 0) return;
                        if (qty < stock) {
                          setState(() => _quantities[id] = qty + 1);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Maksimal pemesanan sesuai sisa stok ($stock sak).',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.orange[800],
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),
              const SizedBox(height: 8),

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.alto),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.cerulean,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              currentPaymentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_paymentMethods.isNotEmpty)
                      DropdownButton<dynamic>(
                        value: currentPaymentId,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.cerulean,
                        ),
                        items: _paymentMethods.map((m) {
                          return DropdownMenuItem<dynamic>(
                            value: m['id'],
                            child: Text(
                              (m['name'] ?? '').toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (selectedId) {
                          if (selectedId == null) return;
                          for (final m in _paymentMethods) {
                            if (m['id'] == selectedId) {
                              setState(() {
                                _selectedPaymentMethod =
                                    Map<String, dynamic>.from(m);
                              });
                              break;
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Misal: Taruh di dalam freezer bagian belakang kafe',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.black50,
                  ),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                        'Rp. ${_formatRupiah(_totalPrice)}',
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
                      backgroundColor:
                          canOrder ? AppColors.cerulean : AppColors.alto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: canOrder ? _submitOrder : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            allOutOfStock ? 'Stok Habis' : 'Pesan',
                            style: const TextStyle(
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
            color: isSelected
                ? AppColors.cerulean
                : AppColors.cerulean.withValues(alpha: 0.5),
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

  Widget _buildProductCard({
    required String title,
    required String subtitle,
    required String price,
    required String unit,
    required int stock,
    required int quantity,
    required VoidCallback onTapQuantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final bool isOutOfStock = stock <= 0;
    final bool isLowStock = stock > 0 && stock <= 5;
    final bool canIncrement = !isOutOfStock && quantity < stock;

    final Color badgeBgColor = isOutOfStock
        ? Colors.red.withValues(alpha: 0.12)
        : isLowStock
            ? Colors.orange.withValues(alpha: 0.14)
            : const Color(0xFF10B981).withValues(alpha: 0.12);

    final Color badgeTextColor = isOutOfStock
        ? Colors.red[700]!
        : isLowStock
            ? Colors.orange[800]!
            : const Color(0xFF059669);

    final String stockLabel = isOutOfStock
        ? 'Stok Habis'
        : isLowStock
            ? 'Sisa $stock $unit'
            : 'Stok: $stock $unit';

    return Opacity(
      opacity: isOutOfStock ? 0.65 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOutOfStock
                ? Colors.red.withValues(alpha: 0.3)
                : AppColors.alto,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? Colors.grey.withValues(alpha: 0.15)
                    : AppColors.pattensBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.ac_unit_rounded,
                color: isOutOfStock ? AppColors.black50 : AppColors.cerulean,
                size: 26,
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
                          title,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stockLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
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
                            color: isOutOfStock
                                ? AppColors.black50
                                : AppColors.cerulean,
                          ),
                        ),
                        TextSpan(
                          text: '/ $unit',
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
            const SizedBox(width: 8),
            Row(
              children: [
                InkWell(
                  onTap: (!isOutOfStock && quantity > 0) ? onDecrement : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (!isOutOfStock && quantity > 0)
                          ? AppColors.pattensBlue
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: (!isOutOfStock && quantity > 0)
                          ? AppColors.black100
                          : AppColors.black50,
                    ),
                  ),
                ),
                // Ketuk angka untuk input cepat jumlah sak (misal ketik 20)
                InkWell(
                  onTap: isOutOfStock ? null : onTapQuantity,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOutOfStock
                            ? AppColors.alto
                            : AppColors.cerulean.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '$quantity',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock
                            ? AppColors.black50
                            : AppColors.black100,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: canIncrement ? onIncrement : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: canIncrement ? AppColors.cerulean : AppColors.alto,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}