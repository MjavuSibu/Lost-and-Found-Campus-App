import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/message_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';
import '../../../shared/services/notification_service.dart';


class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl  = TextEditingController();
  final _scrollCtrl   = ScrollController();
  bool _sending       = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    _messageCtrl.clear();
    setState(() => _sending = true);

    try {
      final convoRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(widget.conversationId);

      await convoRef
          .collection(AppConstants.colMessages)
          .add({
        'senderId':   user.userId,
        'senderName': user.displayName,
        'text':       text,
        'sentAt':     FieldValue.serverTimestamp(),
        'readAt':     null,
      });

      final convoSnap = await convoRef.get();
      final data = convoSnap.data() as Map<String, dynamic>? ?? {};
      final participants =
          List<String>.from(data['participants'] as List? ?? []);
      final unreadCount =
          Map<String, dynamic>.from(data['unreadCount'] as Map? ?? {});

      for (final uid in participants) {
        if (uid != user.userId) {
          unreadCount[uid] = (unreadCount[uid] as int? ?? 0) + 1;
        }
      }

      await convoRef.update({
        'lastMessage':   text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount':   unreadCount,
      });

      for (final uid in participants) {
        if (uid != user.userId) {
          await NotificationService.sendNotification(
            toUserId:       uid,
            title:          'New message from ${user.displayName}',
            body:           text,
            type:           'message',
            conversationId: widget.conversationId,
          );
        }
      }

      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markResolved() async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(widget.conversationId)
        .update({'isResolved': true});

    final parts = widget.conversationId.split('_');
    if (parts.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection(AppConstants.colItems)
          .doc(parts[0])
          .update({
        'status':     AppConstants.statusResolved,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));
    final currentUser =
        ref.watch(currentUserProvider).valueOrNull;

    final convoId = widget.conversationId;
    final convoStream = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(convoId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: convoStream,
      builder: (context, convoSnap) {
        final convoData = convoSnap.data?.data() as Map<String, dynamic>?;
        final itemTitle =
            convoData?['itemTitle'] as String? ?? 'Item';
        final otherName = _getOtherName(convoData, currentUser?.userId);
        final isResolved =
            convoData?['isResolved'] as bool? ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName),
                Text(
                  itemTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!isResolved)
                TextButton(
                  onPressed: _markResolved,
                  child: Text(
                    'Resolve',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.cutGold,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              if (isResolved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: AppColors.foundGreenBg,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: AppColors.foundGreen),
                      const SizedBox(width: 8),
                      Text(
                        'This item has been marked as resolved.',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.foundGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.cutBlue),
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text('Failed to load messages.',
                        style: AppTextStyles.bodyMedium),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No messages yet',
                        subtitle: 'Start the conversation below.',
                      );
                    }
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[i];
                        final isMe =
                            msg.senderId == currentUser?.userId;
                        final showDate = i == 0 ||
                            !_sameDay(
                              messages[i - 1].sentAt,
                              msg.sentAt,
                            );
                        return Column(
                          children: [
                            if (showDate) _dateDivider(msg.sentAt),
                            _MessageBubble(
                              message: msg,
                              isMe: isMe,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              if (!isResolved) _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              style: AppTextStyles.bodyLarge,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: AppTextStyles.bodyMedium,
                filled: true,
                fillColor: AppColors.surface3,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cutBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('d MMM yyyy').format(date),
              style: AppTextStyles.caption,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _getOtherName(
      Map<String, dynamic>? data, String? myUid) {
    if (data == null || myUid == null) return '';
    final participants =
        List<String>.from(data['participants'] as List? ?? []);
    final names = Map<String, String>.from(
        data['participantNames'] as Map? ?? {});
    final otherId = participants.firstWhere(
      (id) => id != myUid,
      orElse: () => '',
    );
    return names[otherId] ?? '';
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.cutBlue : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.sentAt),
              style: AppTextStyles.caption.copyWith(
                color: isMe
                    ? Colors.white.withOpacity(0.65)
                    : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}