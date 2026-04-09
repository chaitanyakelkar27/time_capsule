import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/capsule_card.dart';
import '../capsule/create_capsule_screen.dart';
import '../capsule/capsule_detail_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTab = 0; // 0 = Sent, 1 = Received

  @override
  void initState() {
    super.initState();
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

  String _getUserInitials(String displayName) {
    if (displayName.isEmpty) return 'U';
    return displayName
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final initials = _getUserInitials(user?.displayName ?? '');

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('TimeCapsule', style: AppTheme.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTheme.label.copyWith(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Segmented Toggle ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Row(
                  children: [
                    _buildToggle(
                      'Sent (${capsuleProvider.sentCapsules.length})',
                      0,
                    ),
                    _buildToggle(
                      'Received (${capsuleProvider.receivedCapsules.length})',
                      1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Capsule List ─────────────────────────
            Expanded(
              child: _activeTab == 0
                  ? _buildCapsuleList(
                      capsuleProvider.sentCapsules,
                      isSent: true,
                      emptyMessage: 'No sent capsules yet',
                    )
                  : _buildCapsuleList(
                      capsuleProvider.receivedCapsules,
                      isSent: false,
                      emptyMessage: 'No received capsules yet',
                    ),
            ),

            // ── New Capsule Button ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateCapsuleScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New Capsule'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    ),
                    textStyle: AppTheme.subheading.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String text, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Icon(
                  isSent
                      ? Icons.send_outlined
                      : Icons.mark_email_unread_outlined,
                  size: 32,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: AppTheme.heading.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a capsule to start building your timeline.',
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: capsules.length,
      itemBuilder: (context, index) {
        final capsule = capsules[index];
        return CapsuleCard(
          capsule: capsule,
          isSent: isSent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CapsuleDetailScreen(capsule: capsule, isSent: isSent),
              ),
            );
          },
        );
      },
    );
  }
}
