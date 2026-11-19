import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../service/chat_service.dart';

class OrderChatScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final String roomType; // 'order_chat' (kurir) atau 'consumer_admin' (admin)
  final String recipientName;
  final String recipientSubtitle;
  final String? courierUserId;
  final bool isOrderClosed;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.roomType,
    required this.recipientName,
    required this.recipientSubtitle,
    this.courierUserId,
    this.isOrderClosed = false,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get _isCourierRoom => widget.roomType == 'order_chat';

  List<String> get _quickChips => _isCourierRoom
      ? const [
          'Posisi sudah sampai mana Pak?',
          'Taruh di freezer belakang ya Pak',
          'Titik lokasi sudah sesuai maps',
          'Ditunggu di depan kafe ya Pak',
        ]
      : const [
          'Mohon info status pesanan saya',
          'Bukti pembayaran sudah saya unggah',
          'Apakah pesanan sudah dijadwalkan?',
          'Terima kasih Admin Kube!',
        ];

  @override
  void initState() {
    super.initState();
    ChatService.markIncomingAsRead(
      orderId: widget.orderId,
      roomType: widget.roomType,
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = (presetText ?? _msgController.text).trim();
    if (text.isEmpty || _isSending) return;

    if (presetText == null) {
      _msgController.clear();
    }

    setState(() => _isSending = true);
    try {
      await ChatService.sendMessage(
        orderId: widget.orderId,
        roomType: widget.roomType,
        message: text,
        assignedCourierUserId: widget.courierUserId,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.black100,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _isCourierRoom
                  ? AppColors.cerulean
                  : const Color(0xFF0F766E),
              child: Icon(
                _isCourierRoom
                    ? Icons.local_shipping_rounded
                    : Icons.support_agent_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black100,
                    ),
                  ),
                  Text(
                    '${widget.orderCode} •${widget.recipientSubtitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.black50,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Daftar Pesan Real-Time
          Expanded(
            child: StreamBuilder<List>(
              stream: ChatService.streamOrderMessages(
                orderId: widget.orderId,
                roomType: widget.roomType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.cerulean),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat obrolan:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.pattensBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: AppColors.cerulean,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mulai Percakapan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black100,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isCourierRoom
                                ? 'Tanyakan posisi armada atau beri arahan lokasi pengiriman ke kurir.'
                                : 'Hubungi Admin Kube untuk kendala pembayaran, stok, atau jadwal pengiriman.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.black50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Tandai pesan baru masuk sebagai sudah dibaca & auto-scroll ke bawah
                ChatService.markIncomingAsRead(
                  orderId: widget.orderId,
                  roomType: widget.roomType,
                );
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final msg = messages[idx];
                    final isMe =
                        (msg['sender_id'] ?? '').toString() == _currentUserId;
                    final senderName = (msg['sender_name'] ??
                            (isMe ? 'Saya' : widget.recipientName))
                        .toString();
                    final text = (msg['message'] ?? '').toString();
                    final time = _formatTime(msg['created_at']?.toString());
                    final isRead = msg['is_read'] == true;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.cerulean : AppColors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isMe ? 14 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 14),
                          ),
                          border: isMe
                              ? null
                              : Border.all(color: AppColors.alto),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                senderName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cerulean,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe
                                    ? AppColors.white
                                    : AppColors.black100,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isMe
                                        ? AppColors.white.withValues(alpha: 0.8)
                                        : AppColors.black50,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    isRead
                                        ? Icons.done_all_rounded
                                        : Icons.check_rounded,
                                    size: 12,
                                    color: isRead
                                        ? const Color(0xFFBAE6FD)
                                        : AppColors.white.withValues(alpha: 0.75),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Quick Chat Chips & Input Area
          if (widget.isOrderClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: AppColors.white,
              child: const Text(
                'Pesanan telah selesai/dibatalkan. Riwayat obrolan hanya dapat dilihat.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.black50),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.alto)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Chat Chips
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickChips.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final chipText = _quickChips[idx];
                          return InkWell(
                            onTap: _isSending
                                ? null
                                : () => _handleSend(chipText),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pattensBlue,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.cerulean.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  chipText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cerulean,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // TextField + Tombol Kirim
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgController,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: _isCourierRoom
                                    ? 'Tulis pesan untuk kurir...'
                                    : 'Tulis pesan untuk admin...',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.black50,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide:
                                      const BorderSide(color: AppColors.alto),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide:
                                      const BorderSide(color: AppColors.alto),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: const BorderSide(
                                      color: AppColors.cerulean),
                                ),
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _isSending ? null : () => _handleSend(),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.cerulean,
                                shape: BoxShape.circle,
                              ),
                              child: _isSending
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}