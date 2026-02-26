import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/item_model.dart';
import '../../../shared/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class ItemNotifier extends StateNotifier<AsyncValue<void>> {
  ItemNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> updatePhotos(String itemId, List<String> urls) async {
    await _firestore
        .collection(AppConstants.colItems)
        .doc(itemId)
        .update({'photoUrls': urls});
  }

  Future<String> submitItem({
    required String type,
    required String title,
    required String description,
    required String category,
    required String locationZone,
    required String locationName,
    required String locationDetails,
    required DateTime dateOfIncident,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('Not logged in');

      final itemId = _uuid.v4();
      final item = ItemModel(
        itemId:          itemId,
        type:            type,
        status:          AppConstants.statusOpen,
        title:           title.trim(),
        description:     description.trim(),
        category:        category,
        locationZone:    locationZone,
        locationName:    locationName,
        locationDetails: locationDetails.trim(),
        photoUrls:       [],
        reportedBy:      user.userId,
        reporterName:    user.displayName,
        dateOfIncident:  dateOfIncident,
        createdAt:       DateTime.now(),
        updatedAt:       DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.colItems)
          .doc(itemId)
          .set(item.toFirestore());

      await _firestore
          .collection(AppConstants.colUsers)
          .doc(user.userId)
          .update({'totalPosted': FieldValue.increment(1)});

      state = const AsyncValue.data(null);
      return itemId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final itemNotifierProvider =
    StateNotifierProvider<ItemNotifier, AsyncValue<void>>(
  (ref) => ItemNotifier(ref),
);
