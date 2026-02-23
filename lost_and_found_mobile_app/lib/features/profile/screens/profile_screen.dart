import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/item_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

final _myItemsProvider = StreamProvider<List<ItemModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .where('reportedBy', isEqualTo: uid)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(ItemModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser  = ref.watch(currentUserProvider).valueOrNull;
    final myItemsAsync = ref.watch(_myItemsProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.cutBlue),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.cutBlue,
            actions: [
              IconButton(
  icon: const Icon(Icons.logout_rounded),
  onPressed: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Log Out', style: AppTextStyles.h2),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lostRed,
            ),
            child: Text(
              'Log Out',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.lostRed,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  },
),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cutBlue, AppColors.cutBlueMid],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      UserAvatar(
                        initials: currentUser.initials,
                        photoUrl: currentUser.avatarUrl,
                        size: 72,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentUser.displayName,
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatsRow(currentUser.totalPosted,
                    currentUser.totalResolved),
                const SizedBox(height: 16),
                _buildInfoCard(currentUser.studentNumber, currentUser.role),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('My Posts', style: AppTextStyles.h2),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          myItemsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.cutBlue),
                  ),
                ),
              ),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Center(
                child: Text('Failed to load items.',
                    style: AppTextStyles.bodyMedium),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No posts yet',
                    subtitle:
                        'Items you report will appear here.',
                    buttonLabel: 'Post an Item',
                    onButton: () => context.push(AppRoutes.post),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _MyItemCard(item: items[i]),
                  ),
                  childCount: items.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int posted, int resolved) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Posts',
              value: '$posted',
              icon: Icons.upload_rounded,
              color: AppColors.cutBlue,
              bg: AppColors.surface3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Resolved',
              value: '$resolved',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.foundGreen,
              bg: AppColors.foundGreenBg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Active',
              value: '${posted - resolved < 0 ? 0 : posted - resolved}',
              icon: Icons.pending_outlined,
              color: AppColors.warning,
              bg: AppColors.warningBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String studentNumber, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _infoRow(
              Icons.badge_outlined,
              'Student Number',
              studentNumber,
            ),
            const Divider(height: 20),
            _infoRow(
              Icons.verified_user_outlined,
              'Role',
              role[0].toUpperCase() + role.substring(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.cutBlue),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.bodyLarge),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.h1.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _MyItemCard extends StatelessWidget {
  final ItemModel item;
  const _MyItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cat = AppConstants.categories.firstWhere(
      (c) => c.id == item.category,
      orElse: () => AppConstants.categories.last,
    );
    return GestureDetector(
      onTap: () => context.push(AppRoutes.toItemDetail(item.itemId)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.isLost
                    ? AppColors.lostRedBg
                    : AppColors.foundGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                cat.icon,
                size: 24,
                color: item.isLost
                    ? AppColors.lostRed
                    : AppColors.foundGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ItemTypeBadge(type: item.type, small: true),
                      const SizedBox(width: 6),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: AppTextStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.locationName,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}