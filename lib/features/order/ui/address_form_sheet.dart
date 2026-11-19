import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../theme/app_colors.dart';
import '../service/order_service.dart';

class AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  final bool isFirstAddress;

  const AddressFormSheet({
    super.key,
    this.existingAddress,
    this.isFirstAddress = false,
  });

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final TextEditingController _labelCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final MapController _mapController = MapController();

  // Default titik awal: Purwokerto
  LatLng _selectedPoint = const LatLng(-7.4244, 109.2302);
  bool _hasPinCoordinate = false;
  bool _isLocating = false;
  bool _isReverseGeocoding = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAddress;
    if (existing != null) {
      _labelCtrl.text = (existing['raw_label'] ?? existing['label'] ?? '')
          .toString()
          .replaceAll(' (Alamat Profil)', '')
          .trim();
      _addressCtrl.text = (existing['address'] ?? '').toString().trim();

      final lat = (existing['latitude'] as num?)?.toDouble();
      final lng = (existing['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _selectedPoint = LatLng(lat, lng);
        _hasPinCoordinate = true;
      } else {
        // Jika edit alamat lama yang belum punya koordinat, otomatis coba deteksi lokasi saat ini
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _useCurrentLocation(overwriteAddressText: false);
        });
      }
    } else {
      // Saat tambah alamat baru, otomatis ambil titik GPS user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _useCurrentLocation(overwriteAddressText: true);
      });
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation({bool overwriteAddressText = true}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi (GPS) perangkat belum aktif.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak. Aktifkan izin lokasi di browser/pengaturan perangkat.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _selectedPoint = point;
        _hasPinCoordinate = true;
      });
      _mapController.move(point, 17.0);

      if (overwriteAddressText || _addressCtrl.text.trim().isEmpty) {
        await _reverseGeocode(point);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.orange[800],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Ubah koordinat titik peta menjadi teks alamat riil menggunakan OpenStreetMap Nominatim
  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&accept-language=id',
      );
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'KubeCrystalIceApp/1.0'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] ?? '').toString().trim();
        if (displayName.isNotEmpty && mounted) {
          setState(() {
            _addressCtrl.text = displayName;
          });
        }
      }
    } catch (_) {
      // Abaikan jika gagal reverse geocode; user tetap bisa mengetik manual
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _saveAddress() async {
    final lbl = _labelCtrl.text.trim();
    final addr = _addressCtrl.text.trim();

    if (lbl.isEmpty || addr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama outlet/label lokasi dan alamat lengkap wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final double? lat = _hasPinCoordinate ? _selectedPoint.latitude : null;
      final double? lng = _hasPinCoordinate ? _selectedPoint.longitude : null;

      Map<String, dynamic> savedResult;
      if (_isEditMode) {
        final existing = widget.existingAddress!;
        final bool isPrimary = existing['is_primary'] == true;
        savedResult = await OrderService.updateConsumerAddress(
          addressId: existing['id']?.toString(),
          label: lbl,
          address: addr,
          latitude: lat,
          longitude: lng,
          isPrimaryProfile: isPrimary,
        );
      } else {
        // Alamat baru otomatis jadi alamat utama untuk Order dan Profil
        savedResult = await OrderService.addConsumerAddress(
          label: lbl,
          address: addr,
          latitude: lat,
          longitude: lng,
          setAsPrimaryProfile: true,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, savedResult);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan alamat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 14),
            Text(
              _isEditMode
                  ? 'Ubah Alamat Pengiriman'
                  : (widget.isFirstAddress
                      ? 'Atur Alamat Utama Pengiriman'
                      : 'Tambah Alamat Baru (Otomatis Utama)'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black100,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEditMode
                  ? 'Geser titik peta atau perbarui detail alamat outlet.'
                  : 'Alamat baru akan otomatis menjadi alamat utama untuk Order dan Profil.',
              style: const TextStyle(fontSize: 11, color: AppColors.black50),
            ),
            const SizedBox(height: 14),

            // Peta Interaktif + Tombol Gunakan Lokasi Saat Ini
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.alto),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: 16.0,
                        onTap: (_, latLng) {
                          setState(() {
                            _selectedPoint = latLng;
                            _hasPinCoordinate = true;
                          });
                          _reverseGeocode(latLng);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.kube.crystal_ice',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPoint,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 42,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Tombol "Gunakan Titik Sekarang" di pojok kanan bawah peta
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.cerulean,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppColors.cerulean),
                          ),
                        ),
                        onPressed: _isLocating
                            ? null
                            : () => _useCurrentLocation(
                                  overwriteAddressText: true,
                                ),
                        icon: _isLocating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cerulean,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: Text(
                          _isLocating ? 'Mencari GPS...' : 'Titik Sekarang',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Badge koordinat di pojok kiri atas peta
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _hasPinCoordinate
                              ? '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}'
                              : 'Ketuk peta untuk tandai titik',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tips: Ketuk pada peta untuk memindahkan pin atau tekan "Titik Sekarang".',
              style: TextStyle(fontSize: 10, color: AppColors.black50),
            ),
            const SizedBox(height: 14),

            const Text(
              'Nama Outlet / Label Lokasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black70,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                hintText: 'Misal: Kopi Kenangan Senja / Outlet Utama',
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
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alamat Lengkap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black70,
                  ),
                ),
                if (_isReverseGeocoding)
                  const Text(
                    'Mengambil nama jalan...',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.cerulean,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Nama jalan, nomor rumah/toko, kelurahan, kecamatan, dan patokan...',
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
            const SizedBox(height: 16),

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
                onPressed: _isSaving ? null : _saveAddress,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        _isEditMode
                            ? 'Simpan Perubahan Alamat'
                            : 'Simpan & Jadikan Alamat Utama',
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
    );
  }
}