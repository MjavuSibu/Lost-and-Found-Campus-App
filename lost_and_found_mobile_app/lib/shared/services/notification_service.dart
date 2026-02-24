import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? itemId,
    String? conversationId,
  }) async {
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(toUserId)
        .collection(AppConstants.colNotifications)
        .add({
      'title':          title,
      'body':           body,
      'type':           type,
      'itemId':         itemId,
      'conversationId': conversationId,
      'read':           false,
      'createdAt':      FieldValue.serverTimestamp(),
    });
  }
}
