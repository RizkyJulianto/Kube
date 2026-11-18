import 'package:supabase_flutter/supabase_flutter.dart';

class HomeService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future getHomeSummary() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {
        'lastOrder': null,
        'activeOrder': null,
        'monthlyTotal': 0,
        'monthlyQty': 0,
      };
    }

    final consumerId = user.id;

    // 0. Ambil daftar produk (id, name, unit_weight_kg, price) sesuai skema tabel products
    final Map<dynamic, Map<String, dynamic>> productMap = {};
    try {
      final productsList = await _client
          .from('products')
          .select('id, name, unit_weight_kg, price');
      for (final p in (productsList as List)) {
        productMap[p['id']] = Map<String, dynamic>.from(p as Map);
      }
    } catch (_) {}

    // 1. Ambil 1 pesanan terakhir (untuk kartu Order Cepat)
    final rawLastOrder = await _client
        .from('orders')
        .select('''
          id,
          order_code,
          created_at,
          total_amount,
          status:order_status,
          order_items (
            quantity,
            product_id
          )
        ''')
        .eq('consumer_id', consumerId)
        .neq('order_status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    Map<String, dynamic>? lastOrder;
    if (rawLastOrder != null) {
      lastOrder = Map<String, dynamic>.from(rawLastOrder);
      final rawItems = (lastOrder['order_items'] as List?) ?? [];
      lastOrder['order_items'] = rawItems.map((item) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        final prod = productMap[itemMap['product_id']];
        itemMap['products'] = {
          'name': prod?['name'] ?? 'Es Kristal',
          'unit': 'sak',
          'unit_weight_kg': prod?['unit_weight_kg'] ?? 1,
        };
        return itemMap;
      }).toList();
    }

    // 2. Cek apakah ada pesanan yang sedang aktif (pending / processing / delivering)
    final activeOrder = await _client
        .from('orders')
        .select('''
          id,
          order_code,
          created_at,
          total_amount,
          delivery_address,
          status:order_status
        ''')
        .eq('consumer_id', consumerId)
        .inFilter('order_status', ['pending', 'processing', 'delivering'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // 3. Hitung total pengeluaran & jumlah sak khusus bulan berjalan
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final monthlyOrders = await _client
        .from('orders')
        .select('total_amount, order_items(quantity)')
        .eq('consumer_id', consumerId)
        .neq('order_status', 'cancelled')
        .gte('created_at', startOfMonth);

    num totalExpense = 0;
    int totalQty = 0;

    for (final order in monthlyOrders) {
      totalExpense += (order['total_amount'] as num?) ?? 0;
      final items = (order['order_items'] as List?) ?? [];
      for (final item in items) {
        totalQty += (item['quantity'] as num?)?.toInt() ?? 0;
      }
    }

    return {
      'lastOrder': lastOrder,
      'activeOrder': activeOrder,
      'monthlyTotal': totalExpense,
      'monthlyQty': totalQty,
    };
  }
}