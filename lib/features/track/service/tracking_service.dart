import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackingService {
  static final SupabaseClient _client = Supabase.instance.client;

  
  static Future<List> getTrackableOrders() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final ordersRes = await _client
        .from('orders')
        .select('''
          *,
          order_items (
            *,
            products (
              *
            )
          )
        ''')
        .eq('consumer_id', user.id)
        .order('id', ascending: false);

    final List orders = (ordersRes as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final order in orders) {
      order['items'] = order['order_items'] ?? [];
      final deliveryData = await _fetchDeliveryAndCourier(order['id']);
      final delivery = deliveryData['delivery'];
      order['delivery'] = delivery;
      order['courier'] = deliveryData['courier'];
      order['logs'] = await _fetchDeliveryLogs(delivery?['id']);
    }

    return orders;
  }

  static Future _fetchDeliveryAndCourier(
    dynamic orderId,
  ) async {
    try {
      final deliveryRes = await _client
          .from('deliveries')
          .select('*')
          .eq('order_id', orderId)
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (deliveryRes == null) {
        return {'delivery': null, 'courier': null};
      }

      final dynamic rawCourierId = deliveryRes['courier_id'];
      if (rawCourierId == null || rawCourierId.toString().trim().isEmpty) {
        return {'delivery': deliveryRes, 'courier': null};
      }

      final String courierIdStr = rawCourierId.toString().trim();
      final int? profileId = int.tryParse(courierIdStr);

      Map<String, dynamic>? profileRes;
      String courierUserUuid = '';

      if (profileId != null) {
        // Kasus A: deliveries.courier_id merujuk ke courier_profiles.id (integer)
        profileRes = await _client
            .from('courier_profiles')
            .select('*')
            .eq('id', profileId)
            .maybeSingle();
        courierUserUuid = (profileRes?['user_id'] ?? '').toString().trim();
      } else {
        // Kasus B: deliveries.courier_id langsung merujuk ke users.id (UUID)
        courierUserUuid = courierIdStr;
        profileRes = await _client
            .from('courier_profiles')
            .select('*')
            .eq('user_id', courierUserUuid)
            .maybeSingle();
      }

      Map<String, dynamic>? userRes;
      if (courierUserUuid.isNotEmpty) {
        userRes = await _client
            .from('users')
            .select('id, name, phone')
            .eq('id', courierUserUuid)
            .maybeSingle();
      }

      final courierMap = {
        'id': courierUserUuid,
        'profile_id': profileRes?['id'],
        'name': userRes?['name'] ??
            profileRes?['full_name'] ??
            profileRes?['name'] ??
            'Kurir Kube',
        'phone': userRes?['phone'] ?? profileRes?['phone'] ?? '',
        'vehicle_type': profileRes?['vehicle_type'] ?? 'Armada Kube',
        'license_plate': profileRes?['license_plate'] ?? '',
        'delivery_status': (deliveryRes['status'] ?? 'assigned').toString(),
      };

      return {'delivery': deliveryRes, 'courier': courierMap};
    } catch (e) {
      debugPrint('Error memuat delivery/kurir order $orderId: $e');
      return {'delivery': null, 'courier': null};
    }
  }

  static Future<List> _fetchDeliveryLogs(
    dynamic deliveryId,
  ) async {
    if (deliveryId == null) return [];
    try {
      final res = await _client
          .from('delivery_logs')
          .select('*')
          .eq('delivery_id', deliveryId)
          .order('id', ascending: false);
      return (res as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Error memuat delivery_logs delivery $deliveryId: $e');
      return [];
    }
  }

  /// Konfirmasi pesanan telah diterima oleh konsumen
  static Future<void> confirmOrderReceived(dynamic orderId) async {
    await _client
        .from('orders')
        .update({'order_status': 'completed'})
        .eq('id', orderId);
  }
}