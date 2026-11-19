import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Stream real-time pesan berdasarkan order_id dan room_type
  /// ('order_chat' untuk kurir, 'consumer_admin' untuk admin)
  static Stream<List> streamOrderMessages({
    required int orderId,
    required String roomType,
  }) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: true)
        .map((rows) {
          return rows
              .where((r) => (r['room_type'] ?? '').toString().trim() == roomType)
              .map((r) => Map<String, dynamic>.from(r))
              .toList();
        });
  }

  /// Ambil nama pengirim saat ini dari tabel users (fallback ke email/default)
  static Future<String> _getCurrentSenderName(User user) async {
    try {
      final res = await _client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      final name = (res?['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    } catch (_) {}
    return user.userMetadata?['name']?.toString() ??
        user.email?.split('@').first ??
        'Pelanggan Kube';
  }

  /// Cari fallback UUID untuk kolom courier_user_id (wajib NOT NULL & FK ke users.id)
  /// saat user chat ke admin sebelum kurir ditugaskan.
  static Future<String> _resolveFallbackUserId(String currentUserId) async {
    try {
      final adminRes = await _client
          .from('users')
          .select('id, roles!inner(name)')
          .ilike('roles.name', '%admin%')
          .limit(1)
          .maybeSingle();
      if (adminRes != null && adminRes['id'] != null) {
        return adminRes['id'].toString();
      }
    } catch (_) {}

    try {
      final anyUser = await _client
          .from('users')
          .select('id')
          .neq('id', currentUserId)
          .limit(1)
          .maybeSingle();
      if (anyUser != null && anyUser['id'] != null) {
        return anyUser['id'].toString();
      }
    } catch (_) {}

    return currentUserId;
  }

  /// Kirim pesan baru ke tabel chat_messages
  static Future<void> sendMessage({
    required int orderId,
    required String roomType,
    required String message,
    String? assignedCourierUserId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Sesi pengguna tidak ditemukan.');

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final senderName = await _getCurrentSenderName(user);
    final courierUuid = (assignedCourierUserId != null &&
            assignedCourierUserId.trim().isNotEmpty)
        ? assignedCourierUserId.trim()
        : await _resolveFallbackUserId(user.id);

    await _client.from('chat_messages').insert({
      'room_type': roomType,
      'order_id': orderId,
      'courier_user_id': courierUuid,
      'sender_id': user.id,
      'sender_role': 'consumer',
      'sender_name': senderName,
      'message': trimmed,
      'is_read': false,
    });
  }

  /// Tandai pesan dari lawan bicara sebagai sudah dibaca
  static Future<void> markIncomingAsRead({
    required int orderId,
    required String roomType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('order_id', orderId)
          .eq('room_type', roomType)
          .neq('sender_id', user.id)
          .eq('is_read', false);
    } catch (_) {}
  }
}