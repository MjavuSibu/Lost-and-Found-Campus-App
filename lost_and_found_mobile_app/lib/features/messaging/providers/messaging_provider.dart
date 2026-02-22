import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/message_model.dart';
import '../../../shared/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

final conversationsProvider =
    StreamProvider<List<ConversationModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.colConversations)
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(ConversationModel.fromFirestore).toList());
});

final totalUnreadCountProvider = Provider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return 0;
  final conversations =
      ref.watch(conversationsProvider).valueOrNull ?? [];
  return conversations.fold<int>(
    0,
    (sum, c) => sum + c.unreadFor(uid),
  );
});

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>(
        (ref, conversationId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.colConversations)
      .doc(conversationId)
      .collection(AppConstants.colMessages)
      .orderBy('sentAt', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map(MessageModel.fromFirestore).toList());
});