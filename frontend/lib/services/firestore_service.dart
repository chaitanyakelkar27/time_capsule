import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/capsule_model.dart';
import '../utils/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new capsule
  Future<String> createCapsule(CapsuleModel capsule) async {
    try {
      AppLogger.info(
        'Creating capsule with senderId: ${capsule.senderId}, recipientId: ${capsule.recipientId}',
      );

      final docRef = await _firestore
          .collection('capsules')
          .add(capsule.toMap());

      // Update the capsule with its ID
      await docRef.update({'capsuleId': docRef.id});

      AppLogger.info('Capsule created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating capsule', e);
      throw Exception('Failed to create capsule: $e');
    }
  }

  // Get capsules sent by a user
  Stream<List<CapsuleModel>> getSentCapsules(String userId) {
    AppLogger.debug('Listening to sent capsules for userId: $userId');
    return _firestore
        .collection('capsules')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          AppLogger.debug('Received ${snapshot.docs.length} sent capsules');
          return snapshot.docs
              .map((doc) => CapsuleModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Get capsules received by a user
  Stream<List<CapsuleModel>> getReceivedCapsules(String userId) {
    return _firestore
        .collection('capsules')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CapsuleModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get a specific capsule by ID
  Future<CapsuleModel?> getCapsule(String capsuleId) async {
    try {
      final doc = await _firestore.collection('capsules').doc(capsuleId).get();

      if (doc.exists) {
        return CapsuleModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get capsule: $e');
    }
  }

  // Update capsule status (e.g., unlock)
  Future<void> updateCapsuleStatus({
    required String capsuleId,
    required bool isLocked,
    required String status,
  }) async {
    try {
      await _firestore.collection('capsules').doc(capsuleId).update({
        'isLocked': isLocked,
        'status': status,
        'unlockedAt': isLocked ? null : Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update capsule status: $e');
    }
  }

  // Add reaction to capsule
  Future<void> addReaction({
    required String capsuleId,
    required String reactionVideoUrl,
  }) async {
    try {
      await _firestore.collection('capsules').doc(capsuleId).update({
        'reactionVideoUrl': reactionVideoUrl,
        'reactionRecordedAt': Timestamp.now(),
        'status': 'reacted',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Get contacts for recipient selection
  Future<List<Map<String, dynamic>>> getContacts(String currentUserId) async {
    try {
      AppLogger.info('Fetching contacts for user: $currentUserId');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .orderBy('displayName')
          .get();

      AppLogger.info('Found ${snapshot.docs.length} contacts');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'] ?? doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'email': data['email'],
        };
      }).toList();
    } on FirebaseException catch (e) {
      AppLogger.error('Error fetching contacts: ${e.code} - ${e.message}', e);
      throw Exception('Failed to get contacts: ${e.message ?? e.code}');
    } catch (e) {
      AppLogger.error('Error fetching contacts', e);
      throw Exception('Failed to get contacts: $e');
    }
  }

  // Add a contact by user ID (no global user listing required)
  Future<Map<String, dynamic>> addContactByUserId({
    required String ownerUserId,
    required String contactUserId,
    required String displayName,
  }) async {
    try {
      if (ownerUserId == contactUserId) {
        throw Exception('You cannot add yourself as a contact.');
      }

      final safeDisplayName = displayName.trim().isEmpty
          ? 'Contact'
          : displayName.trim();

      await _firestore
          .collection('users')
          .doc(ownerUserId)
          .collection('contacts')
          .doc(contactUserId)
          .set({
            'userId': contactUserId,
            'displayName': safeDisplayName,
            'addedAt': Timestamp.now(),
          }, SetOptions(merge: true));

      return {'userId': contactUserId, 'displayName': safeDisplayName};
    } on FirebaseException catch (e) {
      AppLogger.error('Error adding contact: ${e.code} - ${e.message}', e);
      throw Exception(e.message ?? 'Failed to add contact');
    } catch (e) {
      AppLogger.error('Error adding contact', e);
      throw Exception('Failed to add contact: $e');
    }
  }

  // Delete a capsule
  Future<void> deleteCapsule(String capsuleId) async {
    try {
      await _firestore.collection('capsules').doc(capsuleId).delete();
    } catch (e) {
      throw Exception('Failed to delete capsule: $e');
    }
  }
}
