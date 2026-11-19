import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Mengambil daftar produk aktif beserta informasi stok terbaru
  static Future<List> getProducts() async {
    final res = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('id', ascending: true);

    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Mengambil daftar metode pembayaran aktif
  static Future<List> getPaymentMethods() async {
    final res = await _client
        .from('payment_methods')
        .select()
        .order('id', ascending: true);

    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Mengambil daftar alamat tersimpan milik mitra dari tabel consumer_addresses
  static Future<List> getConsumerAddresses() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('consumer_addresses')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<List> getSavedAddresses() =>
      getConsumerAddresses();

  /// Helper untuk menyinkronkan alamat utama ke tabel consumer_profiles
  static Future<void> syncPrimaryProfileAddress({
    String? cafeName,
    required String? address,
    double? latitude,
    double? longitude,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existing = await _client
        .from('consumer_profiles')
        .select('id, cafe_name')
        .eq('user_id', user.id)
        .maybeSingle();

    final payload = <String, dynamic>{
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (cafeName != null) {
      payload['cafe_name'] = cafeName;
    }

    if (existing != null) {
      await _client
          .from('consumer_profiles')
          .update(payload)
          .eq('user_id', user.id);
    } else {
      await _client.from('consumer_profiles').insert({
        'user_id': user.id,
        ...payload,
      });
    }
  }

  /// Tambah alamat baru & otomatis jadikan alamat utama untuk Order dan Profil
  static Future addConsumerAddress({
    required String label,
    required String address,
    double? latitude,
    double? longitude,
    bool setAsPrimaryProfile = true,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    final cleanLabel = label.trim();
    final cleanAddress = address.trim();

    final payload = <String, dynamic>{
      'user_id': user.id,
      'label': cleanLabel,
      'address': cleanAddress,
      'latitude': latitude,
      'longitude': longitude,
    };

    final res = await _client
        .from('consumer_addresses')
        .insert(payload)
        .select()
        .single();

    if (setAsPrimaryProfile) {
      await syncPrimaryProfileAddress(
        cafeName: cleanLabel,
        address: cleanAddress,
        latitude: latitude,
        longitude: longitude,
      );
    }

    return Map<String, dynamic>.from(res as Map);
  }

  static Future addSavedAddress({
    required String label,
    required String address,
    double? latitude,
    double? longitude,
  }) =>
      addConsumerAddress(
        label: label,
        address: address,
        latitude: latitude,
        longitude: longitude,
        setAsPrimaryProfile: true,
      );

  /// Ubah alamat (jika addressId == null, berarti berasal dari profil lama -> simpan ke consumer_addresses)
  static Future updateConsumerAddress({
    String? addressId,
    required String label,
    required String address,
    double? latitude,
    double? longitude,
    required bool isPrimaryProfile,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    final cleanLabel = label.trim();
    final cleanAddress = address.trim();

    Map<String, dynamic> resultMap;

    if (addressId != null && addressId.isNotEmpty) {
      final res = await _client
          .from('consumer_addresses')
          .update({
            'label': cleanLabel,
            'address': cleanAddress,
            'latitude': latitude,
            'longitude': longitude,
          })
          .eq('id', addressId)
          .eq('user_id', user.id)
          .select()
          .single();
      resultMap = Map<String, dynamic>.from(res as Map);
    } else {
      // Migrasi alamat lama yang sebelumnya hanya ada di consumer_profiles ke consumer_addresses
      final res = await _client
          .from('consumer_addresses')
          .insert({
            'user_id': user.id,
            'label': cleanLabel,
            'address': cleanAddress,
            'latitude': latitude,
            'longitude': longitude,
          })
          .select()
          .single();
      resultMap = Map<String, dynamic>.from(res as Map);
    }

    if (isPrimaryProfile) {
      await syncPrimaryProfileAddress(
        cafeName: cleanLabel,
        address: cleanAddress,
        latitude: latitude,
        longitude: longitude,
      );
    }

    return resultMap;
  }

  /// Hapus alamat; jika yang dihapus adalah alamat utama profil, otomatis update/kosongkan profil
  static Future<void> deleteConsumerAddress({
    String? addressId,
    required bool isPrimaryProfile,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    if (addressId != null && addressId.isNotEmpty) {
      await _client
          .from('consumer_addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', user.id);
    }

    if (isPrimaryProfile) {
      // Cek apakah masih ada alamat lain di consumer_addresses
      final remaining = await getConsumerAddresses();
      if (remaining.isNotEmpty) {
        final nextPrimary = remaining.first;
        await syncPrimaryProfileAddress(
          cafeName: (nextPrimary['label'] ?? '').toString(),
          address: (nextPrimary['address'] ?? '').toString(),
          latitude: (nextPrimary['latitude'] as num?)?.toDouble(),
          longitude: (nextPrimary['longitude'] as num?)?.toDouble(),
        );
      } else {
        // Kosongkan alamat & koordinat di consumer_profiles
        await syncPrimaryProfileAddress(
          address: null,
          latitude: null,
          longitude: null,
        );
      }
    }
  }

  static Future<void> deleteSavedAddress(dynamic addressId) =>
      deleteConsumerAddress(
        addressId: addressId?.toString(),
        isPrimaryProfile: false,
      );

  static Future createOrder({
    required dynamic paymentMethodId,
    required num totalAmount,
    required String deliveryAddress,
    dynamic deliveryAddressId,
    required String deliveryType, // 'instant' atau 'scheduled'
    String? scheduledTime,
    String? notes,
    required List<dynamic> items,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    if (items.isEmpty) {
      throw Exception('Pilih minimal 1 produk sebelum memesan.');
    }

    final productIds = items.map((e) => e['product_id']).toList();
    final latestProductsRes = await _client
        .from('products')
        .select('id, name, stock, is_active')
        .inFilter('id', productIds);

    final Map<dynamic, Map<String, dynamic>> latestProductMap = {
      for (final p in (latestProductsRes as List))
        p['id']: Map<String, dynamic>.from(p as Map),
    };

    for (final item in items) {
      final pid = item['product_id'];
      final requestedQty = (item['quantity'] as num?)?.toInt() ?? 0;
      final prod = latestProductMap[pid];

      if (prod == null || prod['is_active'] == false) {
        throw Exception('Salah satu produk sudah tidak tersedia.');
      }

      final currentStock = (prod['stock'] as num?)?.toInt() ?? 0;
      final prodName = (prod['name'] ?? 'Produk').toString();

      if (currentStock <= 0) {
        throw Exception('Stok "$prodName" sudah habis.');
      }
      if (requestedQty > currentStock) {
        throw Exception(
          'Stok "$prodName" tidak mencukupi (tersisa $currentStock sak).',
        );
      }
    }

    final now = DateTime.now();
    final orderCode =
        'KUBE-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final orderPayload = <String, dynamic>{
      'order_code': orderCode,
      'consumer_id': user.id,
      'payment_method_id': paymentMethodId,
      'total_amount': totalAmount,
      'payment_status': 'unpaid',
      'order_status': 'pending',
      'delivery_address': deliveryAddress,
      'delivery_type': deliveryType,
    };

    if (deliveryAddressId != null) {
      orderPayload['delivery_address_id'] = deliveryAddressId;
    }
    if (scheduledTime != null && scheduledTime.trim().isNotEmpty) {
      orderPayload['scheduled_time'] = scheduledTime.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      orderPayload['notes'] = notes.trim();
    }

    final insertedOrder =
        await _client.from('orders').insert(orderPayload).select().single();

    final orderMap = Map<String, dynamic>.from(insertedOrder as Map);
    final dbOrderId = orderMap['id'];

    try {
      final orderItemsPayload = items.map((item) {
        final qty = (item['quantity'] as num?) ?? 0;
        final price = (item['price_per_unit'] as num?) ?? 0;
        final subtotal = (item['subtotal'] as num?) ?? (qty * price);
        return <String, dynamic>{
          'order_id': dbOrderId,
          'product_id': item['product_id'],
          'quantity': qty,
          'price_per_unit': price,
          'subtotal': subtotal,
        };
      }).toList();

      await _client.from('order_items').insert(orderItemsPayload);
    } on PostgrestException catch (e) {
      await _client.from('orders').delete().eq('id', dbOrderId);
      throw Exception(e.message);
    } catch (e) {
      await _client.from('orders').delete().eq('id', dbOrderId);
      rethrow;
    }

    return orderMap;
  }

  /// Mengunggah foto bukti transfer ke bucket payment_proofs & mengubah status menjadi waiting_verification
  static Future<String> uploadPaymentProofAndConfirm({
    required dynamic orderId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final path =
        'proof_${orderId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('payment_proofs').uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType:
                ext.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from('payment_proofs').getPublicUrl(path);

    await _client.from('orders').update({
      'payment_status': 'waiting_verification',
      'payment_proof_url': publicUrl,
    }).eq('id', orderId);

    return publicUrl;
  }
}