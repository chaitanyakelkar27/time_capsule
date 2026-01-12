import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/capsule_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const TimeCapsuleApp());
}

class TimeCapsuleApp extends StatelessWidget {
  const TimeCapsuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CapsuleProvider()),
      ],
      child: MaterialApp(
        title: 'TimeCapsule',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show login screen if not authenticated
            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }
            // Show home screen if authenticated
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
