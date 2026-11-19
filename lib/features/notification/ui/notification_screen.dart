import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../chat/ui/order_chat_screen.dart';
import '../../track/ui/track_screen.dart';
import '../service/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMarkAllRead() async {
    await NotificationService.markAllAsRead();
    await _loadNotifications();
  }

  /// Cari pesanan berdasarkan numeric id ATAU order_code (misal "KUBE-20261119-895056")
  /// Jika reference_id kosong/tidak ketemu, ekstrak kode "KUBE-..." dari judul/pesan notifikasi.
  Future? _resolveOrderFromNotification(
    Map<String, dynamic> notif,
  ) async {
    final client = Supabase.instance.client;
    final String refIdStr = (notif['reference_id'] ?? '').toString().trim();

    if (refIdStr.isNotEmpty) {
      final int? parsedId = int.tryParse(refIdStr);
      if (parsedId != null) {
        final byId = await client
            .from('orders')
            .select('id, order_code, order_status')
            .eq('id', parsedId)
            .maybeSingle();
        if (byId != null) return Map<String, dynamic>.from(byId);
      }

      final byCode = await client
          .from('orders')
          .select('id, order_code, order_status')
          .eq('order_code', refIdStr)
          .maybeSingle();
      if (byCode != null) return Map<String, dynamic>.from(byCode);
    }

    // Fallback: cari pola kode pesanan KUBE-XXXX-XXXX di title atau message notifikasi
    final combinedText =
        '${notif['title'] ?? ''} ${notif['message'] ?? ''}';
    final match = RegExp(r'KUBE-[A-Za-z0-9-]+').firstMatch(combinedText);
    if (match != null) {
      final extractedCode = match.group(0)!;
      final byExtracted = await client
          .from('orders')
          .select('id, order_code, order_status')
          .eq('order_code', extractedCode)
          .maybeSingle();
      if (byExtracted != null) return Map<String, dynamic>.from(byExtracted);
    }

    return null;
  }

  Future<void> _onTapNotification(Map<String, dynamic> notif) async {
    final id = notif['id'];
    final bool isRead = notif['is_read'] == true;
    final String category = (notif['category'] ?? '').toString().trim();

    if (!isRead && id != null) {
      await NotificationService.markAsRead(id);
      if (mounted) {
        setState(() {
          notif['is_read'] = true;
        });
      }
    }

    if (!mounted) return;

    final orderRes = await _resolveOrderFromNotification(notif);

    // Jika notifikasi chat (chat_courier / chat_admin / chat) -> buka OrderChatScreen yang sama persis dengan menu Lacak
    final bool isChatCategory = category == 'chat_courier' ||
        category == 'chat_admin' ||
        category == 'chat';

    if (isChatCategory && orderRes != null) {
      try {
        final client = Supabase.instance.client;
        final int orderId = int.parse(orderRes['id'].toString());
        final String orderCode =
            (orderRes['order_code'] ?? '#$orderId').toString();
        final String status =
            (orderRes['order_status'] ?? '').toString().toLowerCase();
        final bool isOrderClosed =
            status == 'completed' || status == 'cancelled';
        final bool isCourierChat = category != 'chat_admin';

        String? courierUserId;
        String courierName = 'Kurir Kube';
        String courierSubtitle = 'Armada Kube';

        if (isCourierChat) {
          // 1. Ambil dari deliveries + courier_profiles (sama persis seperti TrackingService)
          final deliv = await client
              .from('deliveries')
              .select('courier_id')
              .eq('order_id', orderId)
              .order('id', ascending: false)
              .limit(1)
              .maybeSingle();

          final rawCourierId = deliv?['courier_id'];
          if (rawCourierId != null) {
            final int? profileId = int.tryParse(rawCourierId.toString());
            Map<String, dynamic>? prof;

            if (profileId != null) {
              prof = await client
                  .from('courier_profiles')
                  .select('user_id, vehicle_type, license_plate')
                  .eq('id', profileId)
                  .maybeSingle();
              courierUserId = prof?['user_id']?.toString();
            } else {
              courierUserId = rawCourierId.toString();
              prof = await client
                  .from('courier_profiles')
                  .select('user_id, vehicle_type, license_plate')
                  .eq('user_id', courierUserId)
                  .maybeSingle();
            }

            final vehicle = (prof?['vehicle_type'] ?? 'Armada Kube').toString().trim();
            final plate = (prof?['license_plate'] ?? '').toString().trim();
            courierSubtitle = plate.isNotEmpty ? '$vehicle - $plate' : vehicle;
          }

          // 2. Fallback: ambil courier_user_id langsung dari chat_messages order ini jika belum dapat
          if (courierUserId == null || courierUserId.isEmpty) {
            final lastMsg = await client
                .from('chat_messages')
                .select('courier_user_id, sender_name, sender_role')
                .eq('order_id', orderId)
                .eq('room_type', 'order_chat')
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
            if (lastMsg != null && lastMsg['courier_user_id'] != null) {
              courierUserId = lastMsg['courier_user_id'].toString();
            }
          }

          // 3. Ambil nama kurir dari tabel users
          if (courierUserId != null && courierUserId.isNotEmpty) {
            final u = await client
                .from('users')
                .select('name')
                .eq('id', courierUserId)
                .maybeSingle();
            if (u?['name'] != null && u!['name'].toString().trim().isNotEmpty) {
              courierName = u['name'].toString().trim();
            }
          }
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderChatScreen(
              orderId: orderId,
              orderCode: orderCode,
              roomType: isCourierChat ? 'order_chat' : 'consumer_admin',
              recipientName: isCourierChat ? courierName : 'Admin Kube',
              recipientSubtitle: isCourierChat
                  ? courierSubtitle
                  : 'Layanan Pelanggan & Konfirmasi',
              courierUserId: courierUserId,
              isOrderClosed: isOrderClosed,
            ),
          ),
        );
        _loadNotifications();
        return;
      } catch (_) {
        // Fallback ke TrackingScreen jika terjadi kendala jaringan
      }
    }

    // Untuk notifikasi pembayaran / pesanan / pengiriman -> buka TrackingScreen langsung ke order terkait
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(
          initialOrderId: orderRes?['id'] ?? notif['reference_id'],
        ),
      ),
    );
    _loadNotifications();
  }

  String _formatTimeAgo(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '';
    final dt = DateTime.tryParse(isoStr)?.toLocal();
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'payment':
        return Icons.payments_rounded;
      case 'delivery':
        return Icons.local_shipping_rounded;
      case 'chat_admin':
        return Icons.support_agent_rounded;
      case 'chat_courier':
      case 'chat':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.ac_unit_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'payment':
        return const Color(0xFF10B981);
      case 'delivery':
        return AppColors.cerulean;
      case 'chat_admin':
      case 'chat_courier':
      case 'chat':
        return const Color(0xFF6366F1);
      default:
        return AppColors.cerulean;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['is_read'] != true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.black100,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black100,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _handleMarkAllRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cerulean,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.cerulean,
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cerulean),
              )
            : _notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 56,
                        color: AppColors.alto,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Belum ada notifikasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black70,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Info status pesanan & pesan baru akan muncul di sini.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black50,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final notif = _notifications[index];
                      final bool isRead = notif['is_read'] == true;
                      final String category =
                          (notif['category'] ?? 'order').toString();
                      final String title =
                          (notif['title'] ?? 'Notifikasi').toString();
                      final String message =
                          (notif['message'] ?? '').toString();
                      final String timeAgo =
                          _formatTimeAgo(notif['created_at']?.toString());
                      final Color iconColor = _getCategoryColor(category);

                      return InkWell(
                        onTap: () => _onTapNotification(notif),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.white
                                : AppColors.pattensBlue.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRead
                                  ? AppColors.alto
                                  : AppColors.cerulean.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category),
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.bold,
                                              color: AppColors.black100,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.black70,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      timeAgo,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.black50,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}