import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    // Calculate statistics
    final totalSent = capsuleProvider.sentCapsules.length;
    final totalReceived = capsuleProvider.receivedCapsules.length;
    final unlockedReceived = capsuleProvider.receivedCapsules
        .where((c) => !c.isLocked)
        .length;
    final lockedReceived = totalReceived - unlockedReceived;
    final withReactions = capsuleProvider.receivedCapsules
        .where((c) => c.hasReaction)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user.displayName, user.email),

            const SizedBox(height: 32),

            // Statistics Cards
            _buildStatisticsSection(
              totalSent: totalSent,
              totalReceived: totalReceived,
              unlockedReceived: unlockedReceived,
              lockedReceived: lockedReceived,
              withReactions: withReactions,
            ),

            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActions(context),

            const SizedBox(height: 32),

            // Account Actions
            _buildAccountActions(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String displayName, String email) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple.withValues(alpha: 0.2),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              email,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),

            // Edit Profile Button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to edit profile
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection({
    required int totalSent,
    required int totalReceived,
    required int unlockedReceived,
    required int lockedReceived,
    required int withReactions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Statistics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.send,
              label: 'Sent',
              value: totalSent.toString(),
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.inbox,
              label: 'Received',
              value: totalReceived.toString(),
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.lock_open,
              label: 'Unlocked',
              value: unlockedReceived.toString(),
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.lock,
              label: 'Locked',
              value: lockedReceived.toString(),
              color: Colors.purple,
            ),
            _buildStatCard(
              icon: Icons.favorite,
              label: 'Reactions',
              value: withReactions.toString(),
              color: Colors.pink,
            ),
            _buildStatCard(
              icon: Icons.star,
              label: 'Total',
              value: (totalSent + totalReceived).toString(),
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildActionTile(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.bar_chart,
          title: 'Statistics',
          subtitle: 'View detailed analytics',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.share,
          title: 'Share App',
          subtitle: 'Invite friends to TimeCapsule',
          onTap: () {
            // TODO: Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon!')),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help or send feedback',
          onTap: () {
            // TODO: Navigate to help screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.blue),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy Policy coming soon!'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.green),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show terms of service
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terms of Service coming soon!'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Sign Out'),
                onTap: () => _showSignOutDialog(context, authProvider),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Account'),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // App Version
        Center(
          child: Text(
            'TimeCapsule v1.0.0',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Future<void> _showSignOutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your capsules will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion feature coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
