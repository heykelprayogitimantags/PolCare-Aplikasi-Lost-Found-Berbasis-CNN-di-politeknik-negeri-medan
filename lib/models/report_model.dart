import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class ReportModel {
  final String reportId;
  final String title;
  final String description;
  final String status;
  final String category;
  final String? brand;
  final String? dominantColor;
  final List<String>? tags;

  final String locationName;
  final GeoPoint? locationGeoPoint;

  final String? imageUrl;
  final List<num>? featureVector;

  final String? contactInfo;
  final bool isAnonymous;

  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhoto;

  final int commentCount;
  final Timestamp reportDate;
  final Timestamp createdAt;
  final Timestamp lastUpdatedAt;
  
  // ⭐ FIELD BARU UNTUK FITUR RESOLVED
  final bool? isResolved;
  final Timestamp? resolvedAt;

  ReportModel({
    required this.reportId,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    this.brand,
    this.dominantColor,
    this.tags,
    required this.locationName,
    this.locationGeoPoint,
    this.imageUrl,
    this.featureVector,
    this.contactInfo,
    required this.isAnonymous,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhoto,
    this.commentCount = 0,
    required this.reportDate,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.isResolved, // ⭐ TAMBAHAN
    this.resolvedAt, // ⭐ TAMBAHAN
  });

  // Helper untuk konversi ke LatLng
  LatLng? get latLng {
    if (locationGeoPoint == null) return null;
    return LatLng(
      locationGeoPoint!.latitude,
      locationGeoPoint!.longitude,
    );
  }

  // Helper untuk mendapatkan latitude
  double? get latitude => locationGeoPoint?.latitude;

  // Helper untuk mendapatkan longitude
  double? get longitude => locationGeoPoint?.longitude;

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse tags
    List<String> tagsList = [];
    if (data['tags'] != null) {
      if (data['tags'] is String) {
        tagsList = [data['tags']];
      } else if (data['tags'] is List) {
        tagsList = List<String>.from(data['tags']);
      }
    }

    // Parse feature vector
    List<num> featureList = [];
    if (data['featureVector'] != null) {
      if (data['featureVector'] is num) {
        featureList = [data['featureVector']];
      } else if (data['featureVector'] is List) {
        featureList = List<num>.from(data['featureVector']);
      }
    }

    // Parse image URL
    String? image;
    if (data['imageUrl'] != null) {
      if (data['imageUrl'] is List && data['imageUrl'].isNotEmpty) {
        image = data['imageUrl'][0];
      } else if (data['imageUrl'] is String) {
        image = data['imageUrl'];
      }
    }

    return ReportModel(
      reportId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'lost',
      category: data['category'] ?? '',
      brand: data['brand'],
      dominantColor: data['dominantColor'],
      tags: tagsList,
      locationName: data['locationName'] ?? '',
      locationGeoPoint: data['locationGeoPoint'],
      imageUrl: image,
      featureVector: featureList,
      contactInfo: data['contactInfo'],
      isAnonymous: data['isAnonymous'] ?? false,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhoto: data['userPhoto'],
      commentCount: data['commentCount'] ?? 0,
      reportDate: data['reportDate'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastUpdatedAt: data['lastUpdatedAt'] ?? Timestamp.now(),
      isResolved: data['isResolved'] ?? false, // ⭐ TAMBAHAN
      resolvedAt: data['resolvedAt'], // ⭐ TAMBAHAN
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'category': category,
      'brand': brand,
      'dominantColor': dominantColor,
      'tags': tags ?? [],
      'locationName': locationName,
      'locationGeoPoint': locationGeoPoint,
      'imageUrl': imageUrl,
      'featureVector': featureVector ?? [],
      'contactInfo': contactInfo,
      'isAnonymous': isAnonymous,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhoto': userPhoto,
      'commentCount': commentCount,
      'reportDate': reportDate,
      'createdAt': createdAt,
      'lastUpdatedAt': lastUpdatedAt,
      'isResolved': isResolved ?? false, // ⭐ TAMBAHAN
      'resolvedAt': resolvedAt, // ⭐ TAMBAHAN
    };
  }

  // ⭐ Method copyWith untuk update state
  ReportModel copyWith({
    String? reportId,
    String? title,
    String? description,
    String? status,
    String? category,
    String? brand,
    String? dominantColor,
    List<String>? tags,
    String? locationName,
    GeoPoint? locationGeoPoint,
    String? imageUrl,
    List<num>? featureVector,
    String? contactInfo,
    bool? isAnonymous,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhoto,
    int? commentCount,
    Timestamp? reportDate,
    Timestamp? createdAt,
    Timestamp? lastUpdatedAt,
    bool? isResolved,
    Timestamp? resolvedAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      dominantColor: dominantColor ?? this.dominantColor,
      tags: tags ?? this.tags,
      locationName: locationName ?? this.locationName,
      locationGeoPoint: locationGeoPoint ?? this.locationGeoPoint,
      imageUrl: imageUrl ?? this.imageUrl,
      featureVector: featureVector ?? this.featureVector,
      contactInfo: contactInfo ?? this.contactInfo,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhoto: userPhoto ?? this.userPhoto,
      commentCount: commentCount ?? this.commentCount,
      reportDate: reportDate ?? this.reportDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}