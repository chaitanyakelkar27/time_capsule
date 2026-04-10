import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleModel {
  final String capsuleId;
  final String senderId;
  final String recipientId;
  final String senderName;
  final String recipientName;

  // Content
  final String type; // 'text', 'image', 'video', 'audio'
  final String title;
  final String? message; // For text capsules
  final String? mediaUrl; // Storage path for media
  final String? thumbnailUrl; // For video thumbnails

  // Unlock conditions
  final String unlockType; // 'time', 'location', 'both'
  final DateTime? unlockDate; // When capsule unlocks (for time-based)
  final GeoPoint? unlockLocation; // Where capsule unlocks (for location-based)
  final double? unlockRadius; // Radius in meters (default 100)

  // Status
  final String status; // 'locked', 'unlocked', 'reacted'
  final bool isLocked;
  final DateTime? unlockedAt;

  // Reaction
  final String? reactionVideoUrl;
  final DateTime? reactionRecordedAt;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  CapsuleModel({
    required this.capsuleId,
    required this.senderId,
    required this.recipientId,
    required this.senderName,
    required this.recipientName,
    required this.type,
    required this.title,
    this.message,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.unlockType,
    this.unlockDate,
    this.unlockLocation,
    this.unlockRadius,
    required this.status,
    required this.isLocked,
    this.unlockedAt,
    this.reactionVideoUrl,
    this.reactionRecordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'capsuleId': capsuleId,
      'senderId': senderId,
      'recipientId': recipientId,
      'senderName': senderName,
      'recipientName': recipientName,
      'type': type,
      'title': title,
      'message': message,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'unlockType': unlockType,
      'unlockDate': unlockDate != null ? Timestamp.fromDate(unlockDate!) : null,
      'unlockLocation': unlockLocation,
      'unlockRadius': unlockRadius ?? 100.0,
      'status': status,
      'isLocked': isLocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'reactionVideoUrl': reactionVideoUrl,
      'reactionRecordedAt': reactionRecordedAt != null
          ? Timestamp.fromDate(reactionRecordedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory CapsuleModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return fallback;
    }

    final now = DateTime.now();
    final createdAt = parseDate(map['createdAt'], now);

    return CapsuleModel(
      capsuleId: map['capsuleId'] ?? '',
      senderId: map['senderId'] ?? '',
      recipientId: map['recipientId'] ?? '',
      senderName: map['senderName'] ?? '',
      recipientName: map['recipientName'] ?? '',
      type: map['type'] ?? 'text',
      title: map['title'] ?? '',
      message: map['message'],
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      unlockType: map['unlockType'] ?? 'time',
      unlockDate: map['unlockDate'] != null
          ? parseDate(map['unlockDate'], now)
          : null,
      unlockLocation: map['unlockLocation'] as GeoPoint?,
      unlockRadius: map['unlockRadius']?.toDouble(),
      status: map['status'] ?? 'locked',
      isLocked: map['isLocked'] ?? true,
      unlockedAt: map['unlockedAt'] != null
          ? parseDate(map['unlockedAt'], now)
          : null,
      reactionVideoUrl: map['reactionVideoUrl'],
      reactionRecordedAt: map['reactionRecordedAt'] != null
          ? parseDate(map['reactionRecordedAt'], now)
          : null,
      createdAt: createdAt,
      updatedAt: parseDate(map['updatedAt'], createdAt),
    );
  }

  CapsuleModel copyWith({
    String? capsuleId,
    String? senderId,
    String? recipientId,
    String? senderName,
    String? recipientName,
    String? type,
    String? title,
    String? message,
    String? mediaUrl,
    String? thumbnailUrl,
    String? unlockType,
    DateTime? unlockDate,
    GeoPoint? unlockLocation,
    double? unlockRadius,
    String? status,
    bool? isLocked,
    DateTime? unlockedAt,
    String? reactionVideoUrl,
    DateTime? reactionRecordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CapsuleModel(
      capsuleId: capsuleId ?? this.capsuleId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      senderName: senderName ?? this.senderName,
      recipientName: recipientName ?? this.recipientName,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      unlockType: unlockType ?? this.unlockType,
      unlockDate: unlockDate ?? this.unlockDate,
      unlockLocation: unlockLocation ?? this.unlockLocation,
      unlockRadius: unlockRadius ?? this.unlockRadius,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      reactionVideoUrl: reactionVideoUrl ?? this.reactionVideoUrl,
      reactionRecordedAt: reactionRecordedAt ?? this.reactionRecordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isTimeLocked => unlockType == 'time' || unlockType == 'both';
  bool get isLocationLocked => unlockType == 'location' || unlockType == 'both';
  bool get hasReaction => reactionVideoUrl != null;

  // UI lock state used when backend unlock status has not updated yet.
  bool get isEffectivelyLocked {
    if (!isLocked) {
      return false;
    }

    // Time-only capsules should unlock immediately once time passes,
    // even if background unlock job has not run yet.
    if (isTimeLocked && !isLocationLocked && isUnlockTimePassed) {
      return false;
    }

    return true;
  }

  // Media URL getters
  String? get imageUrl => type == 'image' ? mediaUrl : null;
  String? get videoUrl => type == 'video' ? mediaUrl : null;

  // Calculate time remaining until unlock
  Duration? get timeUntilUnlock {
    if (unlockDate == null || !isLocked) return null;
    return unlockDate!.difference(DateTime.now());
  }

  // Check if unlock time has passed
  bool get isUnlockTimePassed {
    if (unlockDate == null) return false;
    return DateTime.now().isAfter(unlockDate!);
  }
}
