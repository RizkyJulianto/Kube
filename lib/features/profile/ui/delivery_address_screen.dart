import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../service/profile_service.dart';

class DeliveryAddressScreen extends StatefulWidget {
  final String initialAddress;
  final double? initialLat;
  final double? initialLng;

  const DeliveryAddressScreen({
    super.key,
    required this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _latController = TextEditingController(
      text: widget.initialLat != null ? widget.initialLat.toString() : '',
    );
    _lngController = TextEditingController(
      text: widget.initialLng != null ? widget.initialLng.toString() : '',
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final address = _addressController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alamat lengkap pengiriman wajib diisi.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ProfileService.updateDeliveryAddress(
        address: address,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat pengiriman berhasil disimpan!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan alamat: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black100),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alamat Pengiriman',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black100),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                  const Text(
                    'Alamat Lengkap Outlet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Jl. Raya Watumas No. 12, Purwokerto Utara (Sebelah Indomaret)',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.black50),
                      contentPadding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Titik Koordinat Google Maps (Opsional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Salin koordinat dari Google Maps agar kurir lebih akurat menuju lokasi.',
                    style: TextStyle(fontSize: 11, color: AppColors.black50),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            hintText: '-7.412345',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.black50),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            hintText: '109.234567',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.black50),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cerulean,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveAddress,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Alamat',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}