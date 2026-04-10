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

      if (capsule.capsuleId.trim().isNotEmpty) {
        final docRef = _firestore.collection('capsules').doc(capsule.capsuleId);
        await docRef.set(capsule.toMap());
        AppLogger.info(
          'Capsule created successfully with provided ID: ${docRef.id}',
        );
        return docRef.id;
      }

      final docRef = await _firestore
          .collection('capsules')
          .add(capsule.toMap());

      // Backward-compatible path when capsule ID is not pre-generated.
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
        .snapshots()
        .map((snapshot) {
          AppLogger.debug('Received ${snapshot.docs.length} sent capsules');
          final capsules = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  if ((data['capsuleId'] as String?)?.isEmpty ?? true) {
                    data['capsuleId'] = doc.id;
                  }
                  return CapsuleModel.fromMap(data);
                } catch (e) {
                  AppLogger.error(
                    'Skipping malformed sent capsule doc ${doc.id}',
                    e,
                  );
                  return null;
                }
              })
              .whereType<CapsuleModel>()
              .toList();

          capsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return capsules;
        });
  }

  // Get capsules received by a user
  Stream<List<CapsuleModel>> getReceivedCapsules(String userId) {
    return _firestore
        .collection('capsules')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final capsules = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  if ((data['capsuleId'] as String?)?.isEmpty ?? true) {
                    data['capsuleId'] = doc.id;
                  }
                  return CapsuleModel.fromMap(data);
                } catch (e) {
                  AppLogger.error(
                    'Skipping malformed received capsule doc ${doc.id}',
                    e,
                  );
                  return null;
                }
              })
              .whereType<CapsuleModel>()
              .toList();

          capsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return capsules;
        });
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
      return snapshot.docs
          .map((doc) {
            final data = doc.data();

            final rawUserId = data['userId'] ?? doc.id;
            final userId = rawUserId is String
                ? rawUserId.trim()
                : rawUserId.toString().trim();

            if (userId.isEmpty) {
              AppLogger.warning(
                'Skipping contact doc ${doc.id} with empty userId',
              );
              return null;
            }

            final rawDisplayName = data['displayName'];
            final displayName =
                rawDisplayName is String && rawDisplayName.trim().isNotEmpty
                ? rawDisplayName.trim()
                : 'Contact';

            final rawEmail = data['email'];
            final email = rawEmail is String ? rawEmail : null;

            return {
              'userId': userId,
              'displayName': displayName,
              'email': email,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
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

      final ownerUserDoc = await _firestore
          .collection('users')
          .doc(ownerUserId)
          .get();

      final ownerDisplayNameRaw =
          ownerUserDoc.data()?['displayName'] as String? ?? 'Contact';
      final ownerDisplayName = ownerDisplayNameRaw.trim().isEmpty
          ? 'Contact'
          : ownerDisplayNameRaw.trim();

      final safeDisplayName = displayName.trim().isEmpty
          ? 'Contact'
          : displayName.trim();

      final now = Timestamp.now();

      // Write owner -> contact
      await _firestore
          .collection('users')
          .doc(ownerUserId)
          .collection('contacts')
          .doc(contactUserId)
          .set({
            'userId': contactUserId,
            'displayName': safeDisplayName,
            'addedAt': now,
          }, SetOptions(merge: true));

      // Best-effort reciprocal write: contact -> owner
      try {
        await _firestore
            .collection('users')
            .doc(contactUserId)
            .collection('contacts')
            .doc(ownerUserId)
            .set({
              'userId': ownerUserId,
              'displayName': ownerDisplayName,
              'addedAt': now,
              'autoLinked': true,
            }, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        AppLogger.warning(
          'Reciprocal contact write failed (${e.code}); owner contact kept',
          e,
        );
      }

      return {'userId': contactUserId, 'displayName': safeDisplayName};
    } on FirebaseException catch (e) {
      AppLogger.error('Error adding contact: ${e.code} - ${e.message}', e);
      throw Exception(e.message ?? 'Failed to add contact');
    } catch (e) {
      AppLogger.error('Error adding contact', e);
      throw Exception('Failed to add contact: $e');
    }
  }

  Future<void> deleteContact({
    required String ownerUserId,
    required String contactUserId,
    bool removeReciprocal = true,
  }) async {
    try {
      if (removeReciprocal) {
        // Delete reciprocal first so firestore rules that check link existence pass.
        try {
          await _firestore
              .collection('users')
              .doc(contactUserId)
              .collection('contacts')
              .doc(ownerUserId)
              .delete();
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied' && e.code != 'not-found') {
            rethrow;
          }
          AppLogger.warning(
            'Reciprocal delete skipped (${e.code}); continuing owner delete',
            e,
          );
        }
      }

      await _firestore
          .collection('users')
          .doc(ownerUserId)
          .collection('contacts')
          .doc(contactUserId)
          .delete();
    } on FirebaseException catch (e) {
      AppLogger.error('Error deleting contact: ${e.code} - ${e.message}', e);
      throw Exception(e.message ?? 'Failed to delete contact');
    } catch (e) {
      AppLogger.error('Error deleting contact', e);
      throw Exception('Failed to delete contact: $e');
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
