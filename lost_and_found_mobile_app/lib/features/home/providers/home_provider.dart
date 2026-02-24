import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/item_model.dart';
import '../../../shared/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

final itemsProvider = StreamProvider<List<ItemModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .where('status', isEqualTo: AppConstants.statusOpen)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(ItemModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

final filteredItemsProvider =
    StreamProvider.family<List<ItemModel>, String>((ref, type) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  if (type == 'all') return ref.watch(itemsProvider.stream);
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .where('status', isEqualTo: AppConstants.statusOpen)
      .where('type', isEqualTo: type)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(ItemModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});
