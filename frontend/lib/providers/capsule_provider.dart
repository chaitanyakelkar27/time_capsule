import 'package:flutter/foundation.dart';
import '../models/capsule_model.dart';
import '../services/firestore_service.dart';

class CapsuleProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CapsuleModel> _sentCapsules = [];
  List<CapsuleModel> _receivedCapsules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CapsuleModel> get sentCapsules => _sentCapsules;
  List<CapsuleModel> get receivedCapsules => _receivedCapsules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Listen to sent capsules
  void listenToSentCapsules(String userId) {
    _firestoreService
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
    _firestoreService
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
      await _firestoreService.createCapsule(capsule);
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

  // Get all users for recipient selection
  Future<List<Map<String, dynamic>>> getUsers(String currentUserId) async {
    try {
      return await _firestoreService.getAllUsers(currentUserId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
