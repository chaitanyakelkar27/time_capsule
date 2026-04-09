import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/capsule_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/capsule/capsule_detail_screen.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'utils/app_logger.dart';
import 'theme/app_theme.dart';

// Global navigator key for navigation from background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const TimeCapsuleApp());
}

class TimeCapsuleApp extends StatefulWidget {
  const TimeCapsuleApp({super.key});

  @override
  State<TimeCapsuleApp> createState() => _TimeCapsuleAppState();
}

class _TimeCapsuleAppState extends State<TimeCapsuleApp> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    _notificationService.setupMessageHandlers(
      onMessageReceived: _handleForegroundNotification,
      onMessageOpened: _handleNotificationTap,
    );
  }

  void _handleForegroundNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.notification?.title ?? 'Notification',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(message.notification?.body ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleNotificationTap(message);
              },
              child: const Text('View'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final capsuleId = message.data['capsuleId'] as String?;
    final context = navigatorKey.currentContext;

    if (capsuleId != null && context != null) {
      try {
        final capsule = await _firestoreService.getCapsule(capsuleId);

        if (capsule != null) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final isSent = capsule.senderId == authProvider.user?.userId;

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  CapsuleDetailScreen(capsule: capsule, isSent: isSent),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Error navigating to capsule', e);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening capsule: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CapsuleProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          AppLogger.debug(
            'Building MaterialApp - isAuthenticated: ${authProvider.isAuthenticated}',
          );

          return MaterialApp(
            key: ValueKey(authProvider.isAuthenticated),
            title: 'TimeCapsule',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.darkTheme,
            home: authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
