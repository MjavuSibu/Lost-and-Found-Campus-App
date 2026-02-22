import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/item_model.dart';
import '../../../router/app_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

final _searchResultsProvider =
    FutureProvider.family<List<ItemModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .where('status', isEqualTo: AppConstants.statusOpen)
      .get();
  final all = snap.docs.map(ItemModel.fromFirestore).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final q = query.toLowerCase();
  return all.where((item) {
    return item.title.toLowerCase().contains(q) ||
        item.description.toLowerCase().contains(q) ||
        item.locationName.toLowerCase().contains(q) ||
        item.category.toLowerCase().contains(q);
  }).toList();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query         = '';
  String _activeType    = 'all';
  String _activeCategory = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ItemModel> _applyFilters(List<ItemModel> items) {
    return items.where((item) {
      final typeMatch =
          _activeType == 'all' || item.type == _activeType;
      final categoryMatch =
          _activeCategory == 'all' || item.category == _activeCategory;
      return typeMatch && categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(_searchResultsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Search items, locations...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.5),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.7)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withOpacity(0.7)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) =>
                  setState(() => _query = val),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          _buildCategoryFilter(),
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyPrompt()
                : resultsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.cutBlue),
                      ),
                    ),
                    error: (_, __) => Center(
                      child: Text('Something went wrong.',
                          style: AppTextStyles.bodyMedium),
                    ),
                    data: (items) {
                      final filtered = _applyFilters(items);
                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No results found',
                          subtitle:
                              'Try different keywords or adjust your filters.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 12, 16, 4),
                            child: Text(
                              '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_query"',
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 40),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) =>
                                  _SearchResultCard(item: filtered[i]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    const types = [
      {'id': 'all',   'label': 'All'},
      {'id': 'lost',  'label': 'Lost'},
      {'id': 'found', 'label': 'Found'},
    ];
    return Container(
      height: 44,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: types.map((t) {
          final isActive = _activeType == t['id'];
          return GestureDetector(
            onTap: () => setState(() => _activeType = t['id']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.cutBlue : AppColors.surface3,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isActive ? AppColors.cutBlue : AppColors.border,
                ),
              ),
              child: Text(
                t['label']!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive
                      ? Colors.white
                      : AppColors.textSecondary,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          _chip('All', 'all', null),
          ...AppConstants.categories
              .map((c) => _chip(c.label, c.id, c.icon)),
        ],
      ),
    );
  }

  Widget _chip(String label, String id, IconData? icon) {
    final isActive = _activeCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = id),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cutBlue : AppColors.surface3,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.cutBlue : AppColors.border,
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
                color: isActive
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_rounded,
                size: 64,
                color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Search for an item',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Type a keyword, location, or category above.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ItemModel item;
  const _SearchResultCard({required this.item});

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          size: 13, color: AppColors.textMuted),
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
    );
  }
}