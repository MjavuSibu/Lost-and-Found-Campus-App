import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/item_model.dart';
import '../../../shared/constants/app_constants.dart';

final itemsProvider = StreamProvider<List<ItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .where('status', isEqualTo: AppConstants.statusOpen)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
});

final filteredItemsProvider =
    StreamProvider.family<List<ItemModel>, String>((ref, type) {
  if (type == 'all') return ref.watch(itemsProvider.stream);
  return FirebaseFirestore.instance
      .collection(AppConstants.colItems)
      .where('status', isEqualTo: AppConstants.statusOpen)
      .where('type', isEqualTo: type)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ItemModel.fromFirestore).toList());
});