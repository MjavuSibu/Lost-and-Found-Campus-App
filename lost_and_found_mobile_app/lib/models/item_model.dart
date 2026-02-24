import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/constants/app_constants.dart';

class ItemModel {
  final String itemId;
  final String type;
  final String status;
  final String title;
  final String description;
  final String category;
  final String locationZone;
  final String locationName;
  final String? locationDetails;
  final List<String> photoUrls;
  final String reportedBy;
  final String reporterName;
  final DateTime dateOfIncident;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final String? claimedBy;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final bool handedToSecurity;

  const ItemModel({
    required this.itemId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.category,
    required this.locationZone,
    required this.locationName,
    this.locationDetails,
    required this.photoUrls,
    required this.reportedBy,
    required this.reporterName,
    required this.dateOfIncident,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.claimedBy,
    this.resolvedAt,
    this.adminNotes,
    this.handedToSecurity = false,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ItemModel(
      itemId:           doc.id,
      type:             d['type']            as String? ?? AppConstants.typeLost,
      status:           d['status']          as String? ?? AppConstants.statusOpen,
      title:            d['title']           as String? ?? '',
      description:      d['description']     as String? ?? '',
      category:         d['category']        as String? ?? 'other',
      locationZone:     d['locationZone']    as String? ?? '',
      locationName:     d['locationName']    as String? ?? '',
      locationDetails:  d['locationDetails'] as String?,
      photoUrls:        List<String>.from(d['photoUrls'] as List? ?? []),
      reportedBy:       d['reportedBy']      as String? ?? '',
      reporterName:     d['reporterName']    as String? ?? '',
      dateOfIncident:   (d['dateOfIncident'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:        (d['createdAt']      as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:        (d['updatedAt']      as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount:        d['viewCount']       as int? ?? 0,
      claimedBy:        d['claimedBy']       as String?,
      resolvedAt:       (d['resolvedAt']     as Timestamp?)?.toDate(),
      adminNotes:       d['adminNotes']      as String?,
      handedToSecurity: d['handedToSecurity'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type':             type,
    'status':           status,
    'title':            title,
    'description':      description,
    'category':         category,
    'locationZone':     locationZone,
    'locationName':     locationName,
    'locationDetails':  locationDetails,
    'photoUrls':        photoUrls,
    'reportedBy':       reportedBy,
    'reporterName':     reporterName,
    'dateOfIncident':   Timestamp.fromDate(dateOfIncident),
    'createdAt':        Timestamp.fromDate(createdAt),
    'updatedAt':        Timestamp.fromDate(updatedAt),
    'viewCount':        viewCount,
    'claimedBy':        claimedBy,
    'resolvedAt':       resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'adminNotes':       adminNotes,
    'handedToSecurity': handedToSecurity,
  };

  bool get isLost     => type == AppConstants.typeLost;
  bool get isFound    => type == AppConstants.typeFound;
  bool get isOpen     => status == AppConstants.statusOpen;
  bool get isResolved => status == AppConstants.statusResolved;
  bool get hasPhotos  => photoUrls.isNotEmpty;
  String get typeLabel => isLost ? 'Lost' : 'Found';

  ItemModel copyWith({
    String? status,
    String? claimedBy,
    DateTime? resolvedAt,
    String? adminNotes,
    bool? handedToSecurity,
    int? viewCount,
    DateTime? updatedAt,
  }) => ItemModel(
    itemId:           itemId,
    type:             type,
    status:           status           ?? this.status,
    title:            title,
    description:      description,
    category:         category,
    locationZone:     locationZone,
    locationName:     locationName,
    locationDetails:  locationDetails,
    photoUrls:        photoUrls,
    reportedBy:       reportedBy,
    reporterName:     reporterName,
    dateOfIncident:   dateOfIncident,
    createdAt:        createdAt,
    updatedAt:        updatedAt        ?? DateTime.now(),
    viewCount:        viewCount        ?? this.viewCount,
    claimedBy:        claimedBy        ?? this.claimedBy,
    resolvedAt:       resolvedAt       ?? this.resolvedAt,
    adminNotes:       adminNotes       ?? this.adminNotes,
    handedToSecurity: handedToSecurity ?? this.handedToSecurity,
  );
}
