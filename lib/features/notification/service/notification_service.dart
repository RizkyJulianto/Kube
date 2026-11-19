import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Stream real-time jumlah notifikasi belum dibaca milik konsumen saat ini
  static Stream<int> unreadCountStream() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('consumer_id', user.id)
        .map((rows) {
          int unread = 0;
          for (final row in rows) {
            if (row['is_read'] != true) {
              unread++;
            }
          }
          return unread;
        });
  }

  
  static Future<List> getNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final res = await _client
        .from('notifications')
        .select()
        .eq('consumer_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  
  static Future<void> markAsRead(dynamic notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  
  static Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('consumer_id', user.id)
        .eq('is_read', false);
  }
}