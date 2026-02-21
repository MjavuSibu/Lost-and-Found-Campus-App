import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ItemCategory {
  final String id;
  final String label;
  final IconData icon;
  const ItemCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

abstract class AppConstants {
  static const List<ItemCategory> categories = [
    ItemCategory(id: 'keys',         label: 'Keys',             icon: Icons.key_rounded),
    ItemCategory(id: 'wallet',       label: 'Wallet / Purse',   icon: Icons.account_balance_wallet_rounded),
    ItemCategory(id: 'phone',        label: 'Phone',            icon: Icons.smartphone_rounded),
    ItemCategory(id: 'student_card', label: 'Student Card',     icon: Icons.badge_rounded),
    ItemCategory(id: 'charger',      label: 'Laptop / Charger', icon: Icons.cable_rounded),
    ItemCategory(id: 'glasses',      label: 'Glasses',          icon: Icons.remove_red_eye_rounded),
    ItemCategory(id: 'bag',          label: 'Bag / Backpack',   icon: Icons.backpack_rounded),
    ItemCategory(id: 'clothing',     label: 'Clothing',         icon: Icons.checkroom_rounded),
    ItemCategory(id: 'stationery',   label: 'Stationery',       icon: Icons.edit_rounded),
    ItemCategory(id: 'headphones',   label: 'Headphones',       icon: Icons.headphones_rounded),
    ItemCategory(id: 'books',        label: 'Book / Notes',     icon: Icons.menu_book_rounded),
    ItemCategory(id: 'other',        label: 'Other',            icon: Icons.more_horiz_rounded),
  ];

  static const Map<String, List<String>> campusLocations = {
    'Zone A — Academic': [
      'Main Library (Building 1)',
      'Lecture Block A (LBA)',
      'Lecture Block B (LBB)',
      'Lecture Block C (LBC)',
      'Engineering Labs',
      'Computer Lab 1',
      'Computer Lab 2',
      'Computer Lab 3',
      'Computer Lab 4',
    ],
    'Zone B — Student Life': [
      'Student Residence A',
      'Student Residence B',
      'Student Residence C',
      'Student Residence D',
      'Dining Hall / Cafeteria',
      'Student Union / SRC',
      'Health & Wellness Centre',
      'Chapel / Prayer Room',
      'Tuck Shop / Vendor Area',
    ],
    'Zone C — Facilities': [
      'Parking Lot — Main Gate',
      'Parking Lot — East Wing',
      'Sports Fields',
      'Security Office',
      'Administration Block',
      'Other / Unspecified',
    ],
  };

  static List<String> get allLocations =>
      campusLocations.values.expand((list) => list).toList();

  static const String colUsers         = 'users';
  static const String colItems         = 'items';
  static const String colConversations = 'conversations';
  static const String colMessages      = 'messages';
  static const String colNotifications = 'notifications';

  static const String storageItemPhotos = 'item_photos';
  static const String storageAvatars    = 'avatars';

  static const List<String> allowedDomains = [
    'student.cut.ac.za',
    'cut.ac.za',
  ];

  static const String typeLost  = 'lost';
  static const String typeFound = 'found';

  static const String statusOpen     = 'open';
  static const String statusClaimed  = 'claimed';
  static const String statusResolved = 'resolved';
  static const String statusArchived = 'archived';

  static const String roleStudent  = 'student';
  static const String roleAdmin    = 'admin';
  static const String roleSecurity = 'security';

  static const int maxPhotos      = 4;
  static const int maxTitleLength = 80;
  static const int maxDescLength  = 1000;

  static const double radiusLg  = 20.0;
  static const double radiusMd  = 16.0;
  static const double radiusSm  = 12.0;
  static const double paddingLg = 24.0;
  static const double paddingMd = 16.0;
  static const double paddingSm = 12.0;
}

extension ItemStatusDisplay on String {
  String get statusLabel {
    switch (this) {
      case AppConstants.statusOpen:     return 'Open';
      case AppConstants.statusClaimed:  return 'Claimed';
      case AppConstants.statusResolved: return 'Resolved';
      case AppConstants.statusArchived: return 'Archived';
      default:                          return this;
    }
  }

  Color get statusColor {
    switch (this) {
      case AppConstants.statusOpen:     return AppColors.warning;
      case AppConstants.statusClaimed:  return AppColors.cutBlueLight;
      case AppConstants.statusResolved: return AppColors.foundGreen;
      case AppConstants.statusArchived: return AppColors.textMuted;
      default:                          return AppColors.textMuted;
    }
  }

  Color get statusBgColor {
    switch (this) {
      case AppConstants.statusOpen:     return AppColors.warningBg;
      case AppConstants.statusClaimed:  return const Color(0xFFEBF2FF);
      case AppConstants.statusResolved: return AppColors.foundGreenBg;
      case AppConstants.statusArchived: return AppColors.surface3;
      default:                          return AppColors.surface3;
    }
  }
}