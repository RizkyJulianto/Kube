import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';
import '../service/order_service.dart';

class OrderSummaryScreen extends StatefulWidget {
  final dynamic orderId;
  final dynamic dbOrderId;
  final String outletName;
  final String outletAddress;
  final String ordererInfo;
  final String deliveryScheduleLabel;
  final Map<dynamic, dynamic> paymentMethod;
  final List<dynamic> orderedItems;
  final num totalAmount;
  final String? notes;
  final String? initialPaymentStatus;
  final String? initialPaymentProofUrl;

  const OrderSummaryScreen({
    super.key,
    required this.orderId,
    required this.dbOrderId,
    required this.outletName,
    required this.outletAddress,
    required this.ordererInfo,
    required this.deliveryScheduleLabel,
    required this.paymentMethod,
    required this.orderedItems,
    required this.totalAmount,
    this.notes,
    this.initialPaymentStatus,
    this.initialPaymentProofUrl,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isConfirming = false;
  bool _isConfirmed = false;
  String? _uploadedProofUrl;

  @override
  void initState() {
    super.initState();
    final initStatus = (widget.initialPaymentStatus ?? '').toLowerCase();
    if (initStatus == 'waiting_verification' || initStatus == 'paid') {
      _isConfirmed = true;
    }
    if (widget.initialPaymentProofUrl != null &&
        widget.initialPaymentProofUrl!.trim().isNotEmpty) {
      _uploadedProofUrl = widget.initialPaymentProofUrl;
    }
  }

  String _formatRupiah(num amount) {
    final intVal = amount.round();
    return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        backgroundColor: AppColors.cerulean,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickAndUploadPaymentProof(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );

      if (picked == null) return;

      setState(() => _isConfirming = true);

      final bytes = await picked.readAsBytes();
      final proofUrl = await OrderService.uploadPaymentProofAndConfirm(
        orderId: widget.dbOrderId,
        fileBytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _isConfirmed = true;
        _uploadedProofUrl = proofUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bukti pembayaran berhasil dikirim! Menunggu verifikasi admin.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah bukti pembayaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unggah Bukti Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black100,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih foto struk transfer atau screenshot bukti pembayaran kamu.',
                style: TextStyle(fontSize: 12, color: AppColors.black50),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pattensBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.cerulean,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPaymentProof(ImageSource.gallery);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pattensBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.cerulean,
                  ),
                ),
                title: const Text(
                  'Ambil Foto Kamera',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPaymentProof(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullProofPreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 260,
                      color: AppColors.white,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.cerulean,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payName = (widget.paymentMethod['name'] ?? 'Tunai').toString();
    final payCode = (widget.paymentMethod['code'] ?? '').toString().toUpperCase();
    final accountNumber =
        (widget.paymentMethod['account_number'] ?? '').toString().trim();
    final accountHolder =
        (widget.paymentMethod['account_holder'] ?? '').toString().trim();
    final qrisUrl =
        (widget.paymentMethod['qris_image_url'] ?? '').toString().trim();

    final isCod = payCode == 'COD' || payName.toLowerCase().contains('tunai');
    final isQris = payCode == 'QRIS' || payName.toLowerCase().contains('qris');
    final isTransfer =
        !isCod && !isQris && (accountNumber.isNotEmpty || payCode.contains('TRF'));

    final currentPayStatus =
        (widget.initialPaymentStatus ?? '').toLowerCase();
    final isPaid = currentPayStatus == 'paid';

    final String headerTitle = isPaid
        ? 'Pembayaran Telah Diverifikasi'
        : (_isConfirmed
            ? 'Bukti Pembayaran Terkirim'
            : 'Pesanan Berhasil Dibuat!');

    final String headerSubtitle = isPaid
        ? 'Pesanan kamu sudah lunas dan siap diproses.'
        : (_isConfirmed
            ? 'Admin Kube sedang memverifikasi bukti transfer kamu.'
            : 'Simpan kode pesanan di bawah untuk memantau pengiriman.');

    final String badgeText = isPaid
        ? 'Lunas'
        : (_isConfirmed
            ? 'Menunggu Verifikasi'
            : (isCod ? 'Bayar di Tempat' : 'Menunggu Bayar'));

    final Color badgeBg = (isPaid || _isConfirmed)
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);

    final Color badgeFg =
        (isPaid || _isConfirmed) ? Colors.green[700]! : Colors.orange[800]!;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ringkasan Pesanan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black100,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Status Atas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pattensBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cerulean.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.cerulean,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (isPaid || _isConfirmed)
                            ? Icons.verified_rounded
                            : Icons.check_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black100,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            headerSubtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.black70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Kode Pesanan & Total
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kode Pesanan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black50,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.orderId.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cerulean,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(
                            widget.orderId.toString(),
                            'Kode pesanan',
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: AppColors.cerulean,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Salin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cerulean,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.alto),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black70,
                          ),
                        ),
                        Text(
                          'Rp. ${_formatRupiah(widget.totalAmount)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Instruksi Pembayaran
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
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: AppColors.cerulean,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Metode Pembayaran: $payName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isCod)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.alto),
                        ),
                        child: const Text(
                          'Siapkan uang tunai sesuai total tagihan saat kurir Kube tiba di lokasi pengiriman.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black70,
                            height: 1.4,
                          ),
                        ),
                      )
                    else if (isTransfer)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.alto),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nomor Rekening Tujuan',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.black50,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  accountNumber.isNotEmpty
                                      ? accountNumber
                                      : '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black100,
                                  ),
                                ),
                                if (accountNumber.isNotEmpty)
                                  InkWell(
                                    onTap: () => _copyToClipboard(
                                      accountNumber,
                                      'Nomor rekening',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pattensBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Salin Rekening',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.cerulean,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (accountHolder.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'a.n. $accountHolder',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else if (isQris)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (qrisUrl.isNotEmpty)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  qrisUrl,
                                  height: 220,
                                  width: 220,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 160,
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Gambar QRIS gagal dimuat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.black50,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Text(
                              'Silakan scan QRIS resmi Kube sesuai total tagihan.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.black70,
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Scan kode QRIS di atas lalu unggah bukti bayar',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.black50,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Preview Bukti Transfer yang sudah diunggah
                    if (_uploadedProofUrl != null &&
                        _uploadedProofUrl!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.alto),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bukti Transfer Terunggah',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black70,
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                _showFullProofPreview(_uploadedProofUrl!),
                            child: const Text(
                              'Perbesar Foto',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cerulean,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showFullProofPreview(_uploadedProofUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _uploadedProofUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 70,
                              alignment: Alignment.center,
                              color: const Color(0xFFF8FAFC),
                              child: const Text(
                                'Foto bukti transfer tersimpan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.black50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Tombol Upload Bukti Pembayaran (khusus non-tunai & belum dikonfirmasi)
                    if (!isCod && !_isConfirmed && !isPaid) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cerulean),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              _isConfirming ? null : _showUploadSourceSheet,
                          icon: _isConfirming
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.cerulean,
                                  ),
                                )
                              : const Icon(
                                  Icons.upload_file_rounded,
                                  size: 18,
                                  color: AppColors.cerulean,
                                ),
                          label: Text(
                            _isConfirming
                                ? 'Mengunggah Bukti...'
                                : 'Saya Sudah Bayar (Upload Bukti)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cerulean,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Rincian Pengiriman & Item
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
                    const Text(
                      'Detail Pengiriman',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Penerima', widget.ordererInfo),
                    const SizedBox(height: 6),
                    _buildDetailRow('Tujuan', widget.outletName),
                    const SizedBox(height: 6),
                    _buildDetailRow('Alamat', widget.outletAddress),
                    const SizedBox(height: 6),
                    _buildDetailRow('Jadwal', widget.deliveryScheduleLabel),
                    if (widget.notes != null &&
                        widget.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildDetailRow('Catatan', widget.notes!.trim()),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.alto),
                    ),
                    const Text(
                      'Rincian Produk',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.orderedItems.map((item) {
                      final name = (item['name'] ?? 'Produk').toString();
                      final qty = (item['quantity'] ?? 0).toString();
                      final subtotal = (item['subtotal'] as num?) ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$name ($qty Sak)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.black70,
                                ),
                              ),
                            ),
                            Text(
                              'Rp. ${_formatRupiah(subtotal)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black100,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Selesai / Kembali
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cerulean,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Selesai & Kembali',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.black50),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.black100,
            ),
          ),
        ),
      ],
    );
  }
}