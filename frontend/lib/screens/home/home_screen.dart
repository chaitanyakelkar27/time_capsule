import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../widgets/capsule_card.dart';
import '../capsule/create_capsule_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to capsules
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final capsuleProvider = Provider.of<CapsuleProvider>(
        context,
        listen: false,
      );

      if (authProvider.user != null) {
        capsuleProvider.listenToSentCapsules(authProvider.user!.userId);
        capsuleProvider.listenToReceivedCapsules(authProvider.user!.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final capsuleProvider = Provider.of<CapsuleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeCapsule ⏰'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.send),
              text: 'Sent (${capsuleProvider.sentCapsules.length})',
            ),
            Tab(
              icon: const Icon(Icons.inbox),
              text: 'Received (${capsuleProvider.receivedCapsules.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sent Capsules
          _buildCapsuleList(
            capsuleProvider.sentCapsules,
            isSent: true,
            emptyMessage:
                'No sent capsules yet.\nCreate your first time capsule!',
          ),
          // Received Capsules
          _buildCapsuleList(
            capsuleProvider.receivedCapsules,
            isSent: false,
            emptyMessage:
                'No received capsules yet.\nWaiting for someone to send you a memory!',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCapsuleScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Capsule'),
      ),
    );
  }

  Widget _buildCapsuleList(
    List capsules, {
    required bool isSent,
    required String emptyMessage,
  }) {
    if (capsules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSent ? Icons.send_outlined : Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: capsules.length,
      itemBuilder: (context, index) {
        final capsule = capsules[index];
        return CapsuleCard(
          capsule: capsule,
          isSent: isSent,
          onTap: () {
            // TODO: Navigate to capsule detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Capsule detail screen coming soon!'),
              ),
            );
          },
        );
      },
    );
  }
}
