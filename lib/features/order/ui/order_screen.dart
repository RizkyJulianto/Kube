import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../theme/app_colors.dart';
import '../../profile/service/profile_service.dart';
import '../service/order_service.dart';
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
  String? _selectedAddressId; // null jika memakai alamat utama dari consumer_profiles
  List _savedAddresses = [];

  List<dynamic> _products = [];
  List<dynamic> _paymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;
  final Map<dynamic, int> _quantities = {};
  bool _isLoadingData = true;
  bool _isSubmitting = false;

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
    List extraAddresses = [];

    // 1. Ambil alamat utama & nama pemesan dari Profil (wajib berhasil duluan)
    try {
      final profileData = await ProfileService.getMitraProfile();
      final user = (profileData['user'] as Map?) ?? {};
      final consumer = (profileData['consumer'] as Map?) ?? {};

      name = (user['name'] ?? 'Mitra Kube').toString().trim();
      cafeName = (consumer['cafe_name'] ?? '').toString().trim();
      primaryAddress = (consumer['address'] ?? '').toString().trim();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedAddressLabel = 'Mitra Kube';
        _selectedAddressText = 'Gagal memuat profil: $e';
        _ordererInfo = 'Pengguna Aktif';
      });
      return;
    }

    // 2. Ambil daftar alamat tambahan dari consumer_addresses secara terpisah
    // (jika gagal/kosong, alamat profil di atas tetap aman & tidak tertimpa)
    try {
      extraAddresses = await OrderService.getConsumerAddresses();
    } catch (_) {
      extraAddresses = [];
    }

    final List combined = [];
    if (primaryAddress.isNotEmpty) {
      combined.add({
        'id': null,
        'label': cafeName.isNotEmpty
            ? '$cafeName (Alamat Profil)'
            : 'Alamat Utama (Profil)',
        'address': primaryAddress,
        'is_primary': true,
      });
    }

    for (final item in extraAddresses) {
      combined.add({
        'id': item['id']?.toString(),
        'label': (item['label'] ?? 'Alamat Tambahan').toString(),
        'address': (item['address'] ?? '').toString(),
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
          _quantities.putIfAbsent(id, () => 0);
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
              Map<String, dynamic>.from(_paymentMethods.first as Map);
        }
      });
    } catch (_) {}
  }

  void _showAddressPickerSheet() {
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
                  'Pilih Alamat Pengiriman',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black100,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih alamat outlet utama atau tambahkan alamat cabang baru.',
                  style: TextStyle(fontSize: 12, color: AppColors.black50),
                ),
                const SizedBox(height: 14),
                if (_savedAddresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Belum ada alamat tersimpan. Tambahkan alamat baru di bawah.',
                        style: TextStyle(fontSize: 12, color: AppColors.black50),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
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
                              children: [
                                Icon(
                                  isPrimary
                                      ? Icons.store_rounded
                                      : Icons.location_on_rounded,
                                  color: AppColors.cerulean,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['label'].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black100,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
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
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.cerulean,
                                    size: 20,
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
                      _showAddNewAddressDialog();
                    },
                    icon: const Icon(
                      Icons.add_location_alt_rounded,
                      color: AppColors.cerulean,
                      size: 20,
                    ),
                    label: const Text(
                      'Tambah Alamat Baru',
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

  void _showAddNewAddressDialog() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
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
                    'Tambah Alamat Pengiriman Baru',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Alamat utama di profil kamu tetap tersimpan dan tidak akan berubah.',
                    style: TextStyle(fontSize: 11, color: AppColors.black50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Label Lokasi / Cabang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      hintText: 'Misal: Cabang GOR / Gudang Freezer 2',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.black50,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.alto),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.alto),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Alamat Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Masukkan nama jalan, nomor, kelurahan/kecamatan, dan patokan...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.black50,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.alto),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.alto),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cerulean,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final lbl = labelCtrl.text.trim();
                              final addr = addressCtrl.text.trim();
                              if (lbl.isEmpty || addr.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Label lokasi dan alamat lengkap wajib diisi',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final created =
                                    await OrderService.addConsumerAddress(
                                  label: lbl,
                                  address: addr,
                                );
                                if (!mounted) return;
                                Navigator.pop(dialogCtx);

                                setState(() {
                                  _selectedAddressId =
                                      created['id']?.toString();
                                  _selectedAddressLabel =
                                      created['label'].toString();
                                  _selectedAddressText =
                                      created['address'].toString();
                                });
                                await _loadUserAndAddresses();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Alamat baru berhasil ditambahkan & dipilih!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan alamat: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Simpan & Gunakan Alamat Ini',
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
            );
          },
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
    if (_totalBag <= 0 || _isSubmitting) return;
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
        if (qty > 0) {
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
                                  color: AppColors.cerulean.withValues(alpha: 0.4),
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
                    child: const Text(
                      'Ubah / Tambah Alamat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cerulean,
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
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.alto),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.cerulean,
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
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.black50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.black50,
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
                  final qty = _quantities[id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProductCard(
                      title: name,
                      subtitle: desc,
                      price: _formatRupiah(price),
                      unit: 'sak',
                      quantity: qty,
                      onDecrement: () {
                        if (qty > 0) {
                          setState(() => _quantities[id] = qty - 1);
                        }
                      },
                      onIncrement: () {
                        setState(() => _quantities[id] = qty + 1);
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
                                    Map<String, dynamic>.from(m as Map);
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
                          _totalBag > 0 ? AppColors.cerulean : AppColors.alto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed:
                        (_totalBag > 0 && !_isSubmitting) ? _submitOrder : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
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
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: AppColors.black100,
                  ),
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
    );
  }
}