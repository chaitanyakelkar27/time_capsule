import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info(
        '📱 Notification permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          AppLogger.info('📱 FCM Token: $token');
          return;
        }
      }

      AppLogger.info('⚠️ Notification permission denied');
    } catch (e) {
      AppLogger.error('❌ Error initializing notifications: $e');
    }
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Save FCM token to user document
  Future<void> saveFCMToken(String userId) async {
    try {
      final token = await getFCMToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'updatedAt': Timestamp.now(),
        });
        AppLogger.info('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      AppLogger.error('❌ Error saving FCM token: $e');
    }
  }

  // Setup message handlers
  void setupMessageHandlers({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpened,
  }) {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('📩 Foreground message received:');
      AppLogger.info('Title: ${message.notification?.title}');
      AppLogger.info('Body: ${message.notification?.body}');
      AppLogger.info('Data: ${message.data}');

      onMessageReceived(message);
    });

    // Background message opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('📩 Background message opened:');
      AppLogger.info('Data: ${message.data}');

      onMessageOpened(message);
    });

    // Check for initial message (app opened from terminated state)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLogger.info('📩 App opened from terminated state:');
        AppLogger.info('Data: ${message.data}');
        onMessageOpened(message);
      }
    });
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('✅ Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('❌ Error unsubscribing from topic: $e');
    }
  }

  // Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      AppLogger.info('✅ FCM token deleted');
    } catch (e) {
      AppLogger.error('❌ Error deleting token: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('📩 Background message received:');
  AppLogger.info('Title: ${message.notification?.title}');
  AppLogger.info('Body: ${message.notification?.body}');
  AppLogger.info('Data: ${message.data}');
}
