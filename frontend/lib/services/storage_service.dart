import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print('❌ Error taking photo: $e');
      return null;
    }
  }

  // Pick video from gallery
  Future<XFile?> pickVideoFromGallery() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
    } catch (e) {
      print('❌ Error picking video: $e');
      return null;
    }
  }

  // Record video from camera
  Future<XFile?> recordVideoFromCamera() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
    } catch (e) {
      print('❌ Error recording video: $e');
      return null;
    }
  }

  // Upload file to Firebase Storage
  Future<String?> uploadFile({
    required XFile file,
    required String folder,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      print('Uploading file to: $folder/$fileName');

      // Create reference
      final ref = _storage.ref().child('$folder/$fileName');

      // Upload file
      final uploadTask = ref.putFile(File(file.path));

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for completion
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      print('✅ File uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      return null;
    }
  }

  // Upload capsule media (image or video)
  Future<String?> uploadCapsuleMedia({
    required XFile file,
    required String capsuleId,
    required String type, // 'image' or 'video'
    Function(double)? onProgress,
  }) async {
    final extension = path.extension(file.path);
    final fileName = '${capsuleId}_$type$extension';

    return await uploadFile(
      file: file,
      folder: 'capsules/$capsuleId',
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  // Upload reaction video
  Future<String?> uploadReactionVideo({
    required XFile file,
    required String capsuleId,
    Function(double)? onProgress,
  }) async {
    final extension = path.extension(file.path);
    final fileName = '${capsuleId}_reaction$extension';

    return await uploadFile(
      file: file,
      folder: 'reactions/$capsuleId',
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  // Delete file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      print('✅ File deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }

  // Get file metadata
  Future<FullMetadata?> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Error getting metadata: $e');
      return null;
    }
  }
}
