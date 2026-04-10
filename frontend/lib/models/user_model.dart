import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.fcmToken,
    required this.createdAt,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final dynamic rawCreatedAt = map['createdAt'];

    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else {
      createdAt = DateTime.now();
    }

    final String resolvedUserId =
        (map['userId'] as String?)?.trim().isNotEmpty == true
        ? (map['userId'] as String).trim()
        : (documentId ?? '');

    return UserModel(
      userId: resolvedUserId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      fcmToken: map['fcmToken'],
      createdAt: createdAt,
    );
  }

  // Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(
    String uid,
    String email,
    String displayName,
  ) {
    return UserModel(
      userId: uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
