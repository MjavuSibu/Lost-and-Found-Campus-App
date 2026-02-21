import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.readAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId:  doc.id,
      senderId:   d['senderId']   as String? ?? '',
      senderName: d['senderName'] as String? ?? '',
      text:       d['text']       as String? ?? '',
      sentAt:     (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt:     (d['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId':   senderId,
    'senderName': senderName,
    'text':       text,
    'sentAt':     Timestamp.fromDate(sentAt),
    'readAt':     readAt != null ? Timestamp.fromDate(readAt!) : null,
  };

  bool get isRead => readAt != null;
}

class ConversationModel {
  final String conversationId;
  final String itemId;
  final String itemTitle;
  final String itemType;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;
  final bool isResolved;

  const ConversationModel({
    required this.conversationId,
    required this.itemId,
    required this.itemTitle,
    required this.itemType,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.isResolved = false,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      conversationId:   doc.id,
      itemId:           d['itemId']    as String? ?? '',
      itemTitle:        d['itemTitle'] as String? ?? '',
      itemType:         d['itemType']  as String? ?? 'lost',
      participants:     List<String>.from(d['participants'] as List? ?? []),
      participantNames: Map<String, String>.from(d['participantNames'] as Map? ?? {}),
      lastMessage:      d['lastMessage']    as String? ?? '',
      lastMessageAt:    (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount:      Map<String, int>.from(d['unreadCount'] as Map? ?? {}),
      isResolved:       d['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'itemId':           itemId,
    'itemTitle':        itemTitle,
    'itemType':         itemType,
    'participants':     participants,
    'participantNames': participantNames,
    'lastMessage':      lastMessage,
    'lastMessageAt':    Timestamp.fromDate(lastMessageAt),
    'unreadCount':      unreadCount,
    'isResolved':       isResolved,
  };

  String otherName(String myUserId) {
    final otherId = participants.firstWhere(
      (id) => id != myUserId,
      orElse: () => '',
    );
    return participantNames[otherId] ?? 'Unknown';
  }

  int unreadFor(String userId) => unreadCount[userId] ?? 0;

  ConversationModel copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    bool? isResolved,
  }) => ConversationModel(
    conversationId:   conversationId,
    itemId:           itemId,
    itemTitle:        itemTitle,
    itemType:         itemType,
    participants:     participants,
    participantNames: participantNames,
    lastMessage:      lastMessage   ?? this.lastMessage,
    lastMessageAt:    lastMessageAt ?? this.lastMessageAt,
    unreadCount:      unreadCount   ?? this.unreadCount,
    isResolved:       isResolved    ?? this.isResolved,
  );
}