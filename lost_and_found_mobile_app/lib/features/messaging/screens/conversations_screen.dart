import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/message_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.cutSage),
          ),
        ),
        error: (error, stack) {
          debugPrint('Conversations error: $error');
          return Center(
            child: Text('$error', style: AppTextStyles.bodyMedium),
          );
        },
        data: (conversations) {
          if (conversations.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              subtitle:
                  'When you claim an item or someone claims yours, your conversation will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, i) {
              final convo = conversations[i];
              final unread =
                  currentUser != null ? convo.unreadFor(currentUser.userId) : 0;
              final otherName = currentUser != null
                  ? convo.otherName(currentUser.userId)
                  : '';
              final initials = otherName.isNotEmpty
                  ? otherName
                      .trim()
                      .split(' ')
                      .where((p) => p.isNotEmpty)
                      .map((p) => p[0])
                      .take(2)
                      .join()
                      .toUpperCase()
                  : '?';

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () =>
                    context.push(AppRoutes.toChat(convo.conversationId)),
                leading: UserAvatar(
                  initials: initials,
                  size: 48,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherName,
                        style: AppTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeago.format(convo.lastMessageAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            convo.itemTitle,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      convo.lastMessage,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight:
                            unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        color: unread > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: unread > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.cutSage,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
