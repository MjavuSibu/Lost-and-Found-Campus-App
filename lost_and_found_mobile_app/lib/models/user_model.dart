import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String studentNumber;
  final String displayName;
  final String email;
  final String role;
  final String? avatarUrl;
  final int totalPosted;
  final int totalResolved;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.studentNumber,
    required this.displayName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.totalPosted = 0,
    this.totalResolved = 0,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId:        doc.id,
      studentNumber: d['studentNumber'] as String? ?? '',
      displayName:   d['displayName']   as String? ?? '',
      email:         d['email']         as String? ?? '',
      role:          d['role']          as String? ?? 'student',
      avatarUrl:     d['avatarUrl']     as String?,
      totalPosted:   d['totalPosted']   as int? ?? 0,
      totalResolved: d['totalResolved'] as int? ?? 0,
      fcmToken:      d['fcmToken']      as String?,
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentNumber': studentNumber,
    'displayName':   displayName,
    'email':         email,
    'role':          role,
    'avatarUrl':     avatarUrl,
    'totalPosted':   totalPosted,
    'totalResolved': totalResolved,
    'fcmToken':      fcmToken,
    'createdAt':     Timestamp.fromDate(createdAt),
  };

  bool get isAdmin   => role == 'admin' || role == 'security';
  bool get isStudent => role == 'student';

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? fcmToken,
    int? totalPosted,
    int? totalResolved,
  }) => UserModel(
    userId:        userId,
    studentNumber: studentNumber,
    displayName:   displayName   ?? this.displayName,
    email:         email,
    role:          role,
    avatarUrl:     avatarUrl     ?? this.avatarUrl,
    totalPosted:   totalPosted   ?? this.totalPosted,
    totalResolved: totalResolved ?? this.totalResolved,
    fcmToken:      fcmToken      ?? this.fcmToken,
    createdAt:     createdAt,
  );
}
