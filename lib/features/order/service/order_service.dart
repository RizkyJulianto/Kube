import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Mengambil daftar produk aktif
  static Future<List> getProducts() async {
    final res = await _client
        .from('products')
        .select()
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

  /// Alias jika dipanggil dengan nama getSavedAddresses
  static Future<List> getSavedAddresses() =>
      getConsumerAddresses();

  /// Menambahkan alamat baru milik mitra ke tabel consumer_addresses
  static Future addConsumerAddress({
    required String label,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
    }

    final payload = <String, dynamic>{
      'user_id': user.id,
      'label': label.trim(),
      'address': address.trim(),
    };
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;

    final res = await _client
        .from('consumer_addresses')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(res as Map);
  }

  /// Alias jika dipanggil dengan nama addSavedAddress
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
      );

  /// Menghapus alamat tersimpan milik mitra
  static Future<void> deleteConsumerAddress(dynamic addressId) async {
    await _client.from('consumer_addresses').delete().eq('id', addressId);
  }

  static Future<void> deleteSavedAddress(dynamic addressId) =>
      deleteConsumerAddress(addressId);

  /// Membuat pesanan baru beserta item-itemnya ke tabel orders dan order_items
  static Future createOrder({
    required dynamic paymentMethodId,
    required num totalAmount,
    required String deliveryAddress,
    dynamic deliveryAddressId,
    required String deliveryType, // 'instant' atau 'scheduled'
    String? scheduledTime,
    String? notes,
    required List items,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
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

    final insertedOrder = await _client
        .from('orders')
        .insert(orderPayload)
        .select()
        .single();

    final orderMap = Map<String, dynamic>.from(insertedOrder as Map);
    final dbOrderId = orderMap['id'];

    if (items.isNotEmpty) {
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