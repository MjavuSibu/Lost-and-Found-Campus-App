import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/item_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/notification_service.dart';

final _itemDetailProvider =
    StreamProvider.family<ItemModel?, String>((ref, itemId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .doc(itemId)
      .snapshots()
      .map((snap) => snap.exists ? ItemModel.fromFirestore(snap) : null);
});

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _showClaimSheet = false;
  final _claimCtrl     = TextEditingController();
  bool _submitting     = false;

  @override
  void dispose() {
    _claimCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitClaim(ItemModel item) async {
    if (_claimCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe how you identify this item.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.lostRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;

      final conversationId =
          '${item.itemId}_${user.userId}';

      final convoRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId);

      final convoSnap = await convoRef.get();
     if (!convoSnap.exists) {
        await convoRef.set({
          'itemId':    item.itemId,
          'itemTitle': item.title,
          'itemType':  item.type,
          'participants':     [item.reportedBy, user.userId],
          'participantNames': {
            item.reportedBy: item.reporterName,
            user.userId:     user.displayName,
          },
          'lastMessage':   _claimCtrl.text.trim(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': {
            item.reportedBy: 1,
            user.userId:     0,
          },
          'isResolved': false,
        });

        await convoRef
            .collection(AppConstants.colMessages)
            .add({
          'senderId':   user.userId,
          'senderName': user.displayName,
          'text':       _claimCtrl.text.trim(),
          'sentAt':     FieldValue.serverTimestamp(),
          'readAt':     null,
        });

        await NotificationService.sendNotification(
          toUserId:       item.reportedBy,
          title:          item.isLost
              ? '${user.displayName} found your item'
              : '${user.displayName} is claiming your item',
          body:           _claimCtrl.text.trim(),
          type:           'claim',
          itemId:         item.itemId,
          conversationId: conversationId,
        );
      }

      if (!mounted) return;
      setState(() => _showClaimSheet = false);
      context.push(AppRoutes.toChat(conversationId));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(_itemDetailProvider(widget.itemId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return itemAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.cutBlue),
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Failed to load item.', style: AppTextStyles.bodyMedium),
        ),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('Item not found.', style: AppTextStyles.bodyMedium),
            ),
          );
        }

        final isOwner = currentUser?.userId == item.reportedBy;
        final cat = AppConstants.categories.firstWhere(
          (c) => c.id == item.category,
          orElse: () => AppConstants.categories.last,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: AppColors.cutBlue,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: item.isLost
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.lostRed,
                                    Color(0xFF8B1A24),
                                  ],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.foundGreen,
                                    Color(0xFF0D6B42),
                                  ],
                                ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  cat.icon,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ItemTypeBadge(type: item.type),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CategoryBadge(categoryId: item.category),
                              const SizedBox(width: 8),
                              StatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(item.title, style: AppTextStyles.displayMedium),
                          const SizedBox(height: 16),

                          _reporterCard(item),
                          const SizedBox(height: 20),

                          _infoRow(
                            Icons.location_on_outlined,
                            'Location',
                            '${item.locationName}, ${item.locationZone}',
                          ),
                          const Divider(height: 24),
                          _infoRow(
                            Icons.calendar_today_outlined,
                            item.isLost ? 'Date Lost' : 'Date Found',
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(item.dateOfIncident),
                          ),
                          if (item.locationDetails != null &&
                              item.locationDetails!.isNotEmpty) ...[
                            const Divider(height: 24),
                            _infoRow(
                              Icons.info_outline_rounded,
                              'Additional Details',
                              item.locationDetails!,
                            ),
                          ],
                          const SizedBox(height: 20),

                          Text('Description', style: AppTextStyles.h3),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (!isOwner && item.isOpen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppOutlineButton(
                            label: 'Message',
                            icon: Icons.chat_bubble_outline_rounded,
                            onTap: () {
                              final conversationId =
                                  '${item.itemId}_${currentUser?.userId}';
                              context.push(AppRoutes.toChat(conversationId));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppGoldButton(
                            label: item.isLost
                                ? 'I Found This'
                                : 'This Is Mine',
                            icon: Icons.back_hand_outlined,
                            onTap: () =>
                                setState(() => _showClaimSheet = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_showClaimSheet) _buildClaimSheet(item),
            ],
          ),
        );
      },
    );
  }

  Widget _reporterCard(ItemModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          UserAvatar(initials: _initials(item.reporterName), size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.reporterName, style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                  'Posted ${timeago.format(item.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.cutBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimSheet(ItemModel item) {
    return GestureDetector(
      onTap: () => setState(() => _showClaimSheet = false),
      child: Container(
        color: Colors.black45,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.isLost ? 'I Found This Item' : 'This Is My Item',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Describe something unique about the item so the reporter can verify your claim.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _claimCtrl,
                    maxLines: 3,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. The keychain has a small red tag with my name on it...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cutBlue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_outlined,
                            size: 16, color: AppColors.cutBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your student number will be shared with the reporter.',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.cutBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppOutlineButton(
                          label: 'Cancel',
                          onTap: () =>
                              setState(() => _showClaimSheet = false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppGoldButton(
                          label: 'Send Claim',
                          isLoading: _submitting,
                          onTap: () => _submitClaim(item),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}