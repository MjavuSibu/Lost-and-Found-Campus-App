import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/item_model.dart';
import '../../../models/user_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

final _allItemsProvider = StreamProvider<List<ItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .snapshots()
      .map((snap) {
    final list = snap.docs.map(ItemModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final _allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.colUsers)
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _filterStatus = 'all';
  int _selectedTab = 0;

  Future<void> _updateStatus(String itemId, String status) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colItems)
        .doc(itemId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Delete Item', style: AppTextStyles.h2),
        content: Text(
          'This action cannot be undone. Are you sure?',
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
              'Delete',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.lostRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection(AppConstants.colItems)
          .doc(itemId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final itemsAsync = ref.watch(_allItemsProvider);

    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Access Denied',
            subtitle: 'You do not have permission to view this page.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _selectedTab == 0
                ? _buildItemsTab(itemsAsync)
                : _buildUsersTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          _tab('Items', 0),
          _tab('Users', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.cutGold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: isActive ? AppColors.cutBlue : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTab(AsyncValue<List<ItemModel>> itemsAsync) {
    return Column(
      children: [
        _buildSummaryRow(itemsAsync.valueOrNull ?? []),
        _buildStatusFilter(),
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.cutBlue),
              ),
            ),
            error: (e, __) => Center(
              child: Text('$e', style: AppTextStyles.bodyMedium),
            ),
            data: (items) {
              final filtered = _filterStatus == 'all'
                  ? items
                  : items.where((i) => i.status == _filterStatus).toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No items',
                  subtitle: 'No items match this filter.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _AdminItemCard(
                  item: filtered[i],
                  onStatusChange: (status) =>
                      _updateStatus(filtered[i].itemId, status),
                  onDelete: () => _deleteItem(filtered[i].itemId),
                  onTap: () =>
                      context.push(AppRoutes.toItemDetail(filtered[i].itemId)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    final usersAsync = ref.watch(_allUsersProvider);
    return usersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.cutBlue),
        ),
      ),
      error: (_, __) => Center(
        child: Text('Something went wrong.', style: AppTextStyles.bodyMedium),
      ),
      data: (users) {
        if (users.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No users found',
            subtitle: 'Registered users will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _UserCard(user: users[i]),
        );
      },
    );
  }

  Widget _buildSummaryRow(List<ItemModel> items) {
    final open = items.where((i) => i.isOpen).length;
    final lost = items.where((i) => i.isLost).length;
    final found = items.where((i) => i.isFound).length;
    final resolved = items.where((i) => i.isResolved).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          _SummaryCard(
              label: 'Open',
              value: '$open',
              color: AppColors.warning,
              bg: AppColors.warningBg),
          const SizedBox(width: 8),
          _SummaryCard(
              label: 'Lost',
              value: '$lost',
              color: AppColors.lostRed,
              bg: AppColors.lostRedBg),
          const SizedBox(width: 8),
          _SummaryCard(
              label: 'Found',
              value: '$found',
              color: AppColors.foundGreen,
              bg: AppColors.foundGreenBg),
          const SizedBox(width: 8),
          _SummaryCard(
              label: 'Resolved',
              value: '$resolved',
              color: AppColors.cutBlue,
              bg: AppColors.surface3),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    const filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'open', 'label': 'Open'},
      {'id': 'claimed', 'label': 'Claimed'},
      {'id': 'resolved', 'label': 'Resolved'},
      {'id': 'archived', 'label': 'Archived'},
    ];

    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: filters.map((f) {
          final isActive = _filterStatus == f['id'];
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f['id']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.cutBlue : AppColors.surface3,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.cutBlue : AppColors.border,
                ),
              ),
              child: Text(
                f['label']!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.h1.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _AdminItemCard extends StatelessWidget {
  final ItemModel item;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _AdminItemCard({
    required this.item,
    required this.onStatusChange,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = AppConstants.categories.firstWhere(
      (c) => c.id == item.category,
      orElse: () => AppConstants.categories.last,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                        const SizedBox(height: 5),
                        Text(
                          item.title,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(item.reporterName,
                                style: AppTextStyles.caption),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(timeago.format(item.createdAt),
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _actionButton(
                  label: 'Archive',
                  icon: Icons.archive_outlined,
                  color: AppColors.textMuted,
                  onTap: () => onStatusChange(AppConstants.statusArchived),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                _actionButton(
                  label: 'Resolve',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.foundGreen,
                  onTap: () => onStatusChange(AppConstants.statusResolved),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                _actionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.lostRed,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  Future<void> _changeRole(BuildContext context, String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Change Role', style: AppTextStyles.h2),
        content: Text(
          'Change ${user.displayName} to $newRole?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.cutBlue),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(user.userId)
          .update({'role': newRole});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          UserAvatar(initials: user.initials, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  'Student No: ${user.studentNumber}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (role) => _changeRole(context, role),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _roleBg(user.role),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _roleColor(user.role)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.role[0].toUpperCase() + user.role.substring(1),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: _roleColor(user.role),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: 16, color: _roleColor(user.role)),
                ],
              ),
            ),
            itemBuilder: (_) => [
              AppConstants.roleStudent,
              AppConstants.roleAdmin,
              AppConstants.roleSecurity,
            ]
                .where((r) => r != user.role)
                .map((r) => PopupMenuItem(
                      value: r,
                      child: Text(
                        r[0].toUpperCase() + r.substring(1),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return AppColors.cutBlue;
      case AppConstants.roleSecurity:
        return AppColors.foundGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _roleBg(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return AppColors.surface3;
      case AppConstants.roleSecurity:
        return AppColors.foundGreenBg;
      default:
        return AppColors.surface3;
    }
  }
}
