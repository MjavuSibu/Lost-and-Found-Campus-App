import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

class _NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? itemId;
  final String? conversationId;
  final bool read;
  final DateTime createdAt;

  const _NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.itemId,
    this.conversationId,
    required this.read,
    required this.createdAt,
  });

  factory _NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _NotificationModel(
      id:             doc.id,
      title:          d['title']          as String? ?? '',
      body:           d['body']           as String? ?? '',
      type:           d['type']           as String? ?? '',
      itemId:         d['itemId']         as String?,
      conversationId: d['conversationId'] as String?,
      read:           d['read']           as bool? ?? false,
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}

final _notificationsProvider =
    StreamProvider<List<_NotificationModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colNotifications)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map(_NotificationModel.fromFirestore)
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .collection(AppConstants.colNotifications)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> _markRead(String uid, String notifId) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .collection(AppConstants.colNotifications)
        .doc(notifId)
        .update({'read': true});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(_notificationsProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cutGold,
                ),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.cutBlue),
          ),
        ),
        error: (_, __) => Center(
          child: Text('Something went wrong.',
              style: AppTextStyles.bodyMedium),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle:
                  'You will be notified when someone claims your item or messages you.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16),
            itemBuilder: (context, i) {
              final notif = notifications[i];
              return _NotificationTile(
                notification: notif,
                onTap: () async {
                  if (uid != null && !notif.read) {
                    await _markRead(uid, notif.id);
                  }
                  if (!context.mounted) return;
                  if (notif.conversationId != null) {
                    context.push(
                        AppRoutes.toChat(notif.conversationId!));
                  } else if (notif.itemId != null) {
                    context.push(
                        AppRoutes.toItemDetail(notif.itemId!));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'claim':   return Icons.back_hand_outlined;
      case 'message': return Icons.chat_bubble_outline_rounded;
      case 'resolved': return Icons.check_circle_outline_rounded;
      default:        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'claim':    return AppColors.cutGold;
      case 'message':  return AppColors.cutBlue;
      case 'resolved': return AppColors.foundGreen;
      default:         return AppColors.textMuted;
    }
  }

  Color get _iconBg {
    switch (notification.type) {
      case 'claim':    return AppColors.warningBg;
      case 'message':  return AppColors.surface3;
      case 'resolved': return AppColors.foundGreenBg;
      default:         return AppColors.surface3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: notification.read
            ? Colors.transparent
            : AppColors.cutBlue.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, size: 22, color: _iconColor),
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
                          notification.title,
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: notification.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.cutBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}