import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/capsule_model.dart';
import '../services/firestore_service.dart';

class CapsuleProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<CapsuleModel>>? _sentSubscription;
  StreamSubscription<List<CapsuleModel>>? _receivedSubscription;

  List<CapsuleModel> _sentCapsules = [];
  List<CapsuleModel> _receivedCapsules = [];
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CapsuleModel> get sentCapsules => _sentCapsules;
  List<CapsuleModel> get receivedCapsules => _receivedCapsules;
  List<Map<String, dynamic>> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Listen to sent capsules
  void listenToSentCapsules(String userId) {
    _sentSubscription?.cancel();
    _sentSubscription = _firestoreService
        .getSentCapsules(userId)
        .listen(
          (capsules) {
            _sentCapsules = capsules;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load sent capsules: $error';
            notifyListeners();
          },
        );
  }

  // Listen to received capsules
  void listenToReceivedCapsules(String userId) {
    _receivedSubscription?.cancel();
    _receivedSubscription = _firestoreService
        .getReceivedCapsules(userId)
        .listen(
          (capsules) {
            _receivedCapsules = capsules;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load received capsules: $error';
            notifyListeners();
          },
        );
  }

  // Create a new capsule
  Future<bool> createCapsule(CapsuleModel capsule) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final capsuleId = await _firestoreService.createCapsule(capsule);

      // Show immediately on sender dashboard while stream catches up.
      final createdCapsule = capsule.copyWith(capsuleId: capsuleId);
      _sentCapsules = [
        createdCapsule,
        ..._sentCapsules.where((c) => c.capsuleId != capsuleId),
      ];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Unlock a capsule
  Future<bool> unlockCapsule(String capsuleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateCapsuleStatus(
        capsuleId: capsuleId,
        isLocked: false,
        status: 'unlocked',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add reaction to capsule
  Future<bool> addReaction(String capsuleId, String reactionVideoUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.addReaction(
        capsuleId: capsuleId,
        reactionVideoUrl: reactionVideoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get contacts for recipient selection
  Future<List<Map<String, dynamic>>> getContacts(String currentUserId) async {
    try {
      final contacts = await _firestoreService.getContacts(currentUserId);
      _contacts = contacts;
      notifyListeners();
      return contacts;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> refreshContacts(String currentUserId) async {
    await getContacts(currentUserId);
  }

  // Add contact by user ID
  Future<Map<String, dynamic>?> addContactByUserId({
    required String ownerUserId,
    required String contactUserId,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final contact = await _firestoreService.addContactByUserId(
        ownerUserId: ownerUserId,
        contactUserId: contactUserId,
        displayName: displayName,
      );

      _contacts = [
        contact,
        ..._contacts.where((c) => c['userId'] != contactUserId),
      ];

      _isLoading = false;
      notifyListeners();
      return contact;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteContact({
    required String ownerUserId,
    required String contactUserId,
  }) async {
    if (ownerUserId.trim().isEmpty || contactUserId.trim().isEmpty) {
      _errorMessage = 'Invalid contact selected for deletion.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteContact(
        ownerUserId: ownerUserId,
        contactUserId: contactUserId,
      );

      _contacts.removeWhere((c) => c['userId'] == contactUserId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete capsule
  Future<bool> deleteCapsule(String capsuleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteCapsule(capsuleId);
      // Remove from local lists
      _sentCapsules.removeWhere((c) => c.capsuleId == capsuleId);
      _receivedCapsules.removeWhere((c) => c.capsuleId == capsuleId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sentSubscription?.cancel();
    _receivedSubscription?.cancel();
    super.dispose();
  }
}
