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

    // 1. Cari consumer_id milik user yang sedang login
    final consumer = await _client
        .from('consumer_profiles')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (consumer == null) {
      return {
        'lastOrder': null,
        'activeOrder': null,
        'monthlyTotal': 0,
        'monthlyQty': 0,
      };
    }

    final consumerId = consumer['id'];

    // 2. Ambil 1 pesanan terakhir (untuk kartu Order Cepat)
    final lastOrder = await _client
        .from('orders')
        .select('''
          id,
          created_at,
          total_amount,
          status,
          order_items (
            quantity,
            product_id,
            products ( name, unit )
          )
        ''')
        .eq('consumer_id', consumerId)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // 3. Cek apakah ada pesanan yang sedang aktif (pending / processing / delivering)
    final activeOrder = await _client
        .from('orders')
        .select('''
          id,
          status,
          courier_profiles (
            users ( name )
          )
        ''')
        .eq('consumer_id', consumerId)
        .inFilter('status', ['pending', 'processing', 'delivering'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // 4. Hitung total pengeluaran & jumlah sak khusus bulan berjalan
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final monthlyOrders = await _client
        .from('orders')
        .select('total_amount, order_items(quantity)')
        .eq('consumer_id', consumerId)
        .neq('status', 'cancelled')
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