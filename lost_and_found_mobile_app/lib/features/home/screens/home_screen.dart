import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';

import '../../../models/item_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab      = 'all';
  String _activeCategory = 'all';

  static const _tabs = [
    {'id': 'all',   'label': 'All Items'},
    {'id': 'lost',  'label': 'Lost'},
    {'id': 'found', 'label': 'Found'},
  ];

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredItemsProvider(_activeTab));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: AppColors.cutSage,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cutSage, AppColors.cutSageMid],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.search_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Lost & Found Campus',
                                style: AppTextStyles.h1
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white),
                              onPressed: () =>
                                  context.push(AppRoutes.notifications),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.search),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Icon(Icons.search_rounded,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Search lost or found items...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildTabs(),
            _buildCategoryFilter(),
            _buildStatsRow(),
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  final filtered = _activeCategory == 'all'
                      ? items
                      : items
                          .where((i) => i.category == _activeCategory)
                          .toList();
                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No items found',
                      subtitle:
                          'Be the first to report a lost or found item on campus.',
                      buttonLabel: 'Post an Item',
                      onButton: () => context.push(AppRoutes.post),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _ItemCard(item: filtered[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.cutSage),
                  ),
                ),
                error: (e, __) => Center(
                  child: Text('$e',
                      style: AppTextStyles.bodyMedium),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.post),
        backgroundColor: AppColors.cutSage,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.cutSage,
      child: Row(
        children: _tabs.map((tab) {
          final isActive = _activeTab == tab['id'];
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab['id']!),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? AppColors.cutGold
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                tab['label']!,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isActive
                      ? AppColors.cutGold
                      : Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _CategoryChip(
            label: 'All',
            isActive: _activeCategory == 'all',
            onTap: () => setState(() => _activeCategory = 'all'),
          ),
          ...AppConstants.categories.map((cat) => _CategoryChip(
                label: cat.label,
                icon: cat.icon,
                isActive: _activeCategory == cat.id,
                onTap: () =>
                    setState(() => _activeCategory = cat.id),
              )),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final itemsAsync = ref.watch(itemsProvider);
    final items = itemsAsync.valueOrNull ?? [];
    final lostCount  = items.where((i) => i.isLost).length;
    final foundCount = items.where((i) => i.isFound).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          _StatChip(
              label: '$lostCount Lost',
              color: AppColors.lostRed,
              bg: AppColors.lostRedBg),
          const SizedBox(width: 8),
          _StatChip(
              label: '$foundCount Found',
              color: AppColors.foundGreen,
              bg: AppColors.foundGreenBg),
          const SizedBox(width: 8),
          _StatChip(
              label: '${items.length} Active',
              color: AppColors.cutSage,
              bg: AppColors.surface3),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cutSage : AppColors.surface3,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.cutSage : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 12,
                  color: isActive
                      ? Colors.white
                      : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color:
                    isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemModel item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cat = AppConstants.categories.firstWhere(
      (c) => c.id == item.category,
      orElse: () => AppConstants.categories.last,
    );

    return GestureDetector(
      onTap: () => context.push(AppRoutes.toItemDetail(item.itemId)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: item.hasPhotos
                    ? Image.memory(
                        base64Decode(item.photoUrls.first),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: item.isLost
                              ? AppColors.lostRedBg
                              : AppColors.foundGreenBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          cat.icon,
                          size: 26,
                          color: item.isLost
                              ? AppColors.lostRed
                              : AppColors.foundGreen,
                        ),
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
                        CategoryBadge(categoryId: item.category),
                        const Spacer(),
                        Text(
                          timeago.format(item.createdAt),
                          style: AppTextStyles.caption,
                        ),
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
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.locationName,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
