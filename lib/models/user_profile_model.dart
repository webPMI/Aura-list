import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile_model.g.dart';

/// User profile model for Firestore synchronization
/// Stores user metadata and preferences
@HiveType(typeId: 8)
class UserProfile {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String? email;

  @HiveField(2)
  final String? displayName;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastLoginAt;

  @HiveField(6)
  final bool hasAcceptedTerms;

  @HiveField(7)
  final String? preferredGuideId;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.hasAcceptedTerms = false,
    this.preferredGuideId,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'hasAcceptedTerms': hasAcceptedTerms,
      'preferredGuideId': preferredGuideId,
    };
  }

  /// Create from Firestore document
  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasAcceptedTerms: data['hasAcceptedTerms'] as bool? ?? false,
      preferredGuideId: data['preferredGuideId'] as String?,
    );
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? hasAcceptedTerms,
    String? preferredGuideId,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      preferredGuideId: preferredGuideId ?? this.preferredGuideId,
    );
  }
}
