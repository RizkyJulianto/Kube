import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Mengambil daftar riwayat pesanan mitra beserta item & metode pembayarannya
  static Future<List> getMitraOrderHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // 1. Ambil semua pesanan milik mitra
    final ordersRes = await _client
        .from('orders')
        .select()
        .eq('consumer_id', user.id)
        .order('created_at', ascending: false);

    final List orders = [];
    for (final row in (ordersRes as List)) {
      orders.add(Map<String, dynamic>.from(row as Map));
    }

    if (orders.isEmpty) return [];

    // 2. Ambil semua metode pembayaran untuk mapping nama & kode
    final payMethodsRes = await _client.from('payment_methods').select();
    final payMethodMap = <dynamic, Map<String, dynamic>>{};
    for (final pm in (payMethodsRes as List)) {
      final itemMap = Map<String, dynamic>.from(pm as Map);
      payMethodMap[itemMap['id']] = itemMap;
    }

    // 3. Ambil seluruh produk untuk mapping nama produk
    final productsRes = await _client.from('products').select('id, name');
    final productNameMap = <dynamic, String>{};
    for (final prod in (productsRes as List)) {
      final prodMap = Map<String, dynamic>.from(prod as Map);
      productNameMap[prodMap['id']] =
          (prodMap['name'] ?? 'Es Kristal').toString();
    }

    // 4. Ambil seluruh order_items untuk order_id yang ditemukan
    final orderIds = orders.map((o) => o['id']).toList();
    final itemsRes = await _client
        .from('order_items')
        .select()
        .inFilter('order_id', orderIds);

    final itemsByOrder = <dynamic, List>{};
    for (final rawItem in (itemsRes as List)) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final oid = item['order_id'];
      final pid = item['product_id'];
      item['product_name'] = productNameMap[pid] ?? 'Es Kristal';
      itemsByOrder.putIfAbsent(oid, () => []).add(item);
    }

    // 5. Gabungkan data ke setiap pesanan
    for (final order in orders) {
      final oid = order['id'];
      final pmId = order['payment_method_id'];
      order['items'] = itemsByOrder[oid] ?? [];
      order['payment_method'] = payMethodMap[pmId] ??
          <String, dynamic>{'id': pmId, 'name': 'Tunai', 'code': 'COD'};
    }

    return orders;
  }
}