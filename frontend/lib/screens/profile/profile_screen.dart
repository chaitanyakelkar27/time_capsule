import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../theme/app_theme.dart';
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
      return Scaffold(
        backgroundColor: AppTheme.scaffold,
        body: Center(child: Text('Not logged in', style: AppTheme.body)),
      );
    }

    final totalSent = capsuleProvider.sentCapsules.length;
    final totalReceived = capsuleProvider.receivedCapsules.length;
    final unlockedReceived = capsuleProvider.receivedCapsules
        .where((c) => !c.isLocked)
        .length;
    final lockedReceived = totalReceived - unlockedReceived;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: AppTheme.heading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            // ── Avatar & Info ─────────────────────────
            _buildProfileHeader(
              context,
              user.displayName,
              user.email,
              user.userId,
            ),
            const SizedBox(height: 20),

            // ── Stats Grid ───────────────────────────
            _buildStatsGrid(
              totalSent: totalSent,
              totalReceived: totalReceived,
              unlockedReceived: unlockedReceived,
              lockedReceived: lockedReceived,
            ),
            const SizedBox(height: 20),

            // ── Settings List ────────────────────────
            _buildSettingsList(context),
            const SizedBox(height: 12),

            // ── Stats Link ───────────────────────────
            _buildSettingsItem(
              context,
              icon: Icons.bar_chart_outlined,
              title: 'Advanced Statistics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Account Actions ──────────────────────
            _buildAccountSection(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String displayName,
    String email,
    String userId,
  ) {
    final initials = displayName.isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .join()
        : 'U';

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppTheme.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: AppTheme.heading.copyWith(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: AppTheme.heading.copyWith(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTheme.body.copyWith(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: Text(
                  'Contact ID: $userId',
                  style: AppTheme.body.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _copyContactId(context, userId),
                icon: const Icon(
                  Icons.copy_outlined,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                tooltip: 'Copy Contact ID',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyContactId(BuildContext context, String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact ID copied'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Widget _buildStatsGrid({
    required int totalSent,
    required int totalReceived,
    required int unlockedReceived,
    required int lockedReceived,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile('SENT', totalSent)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatTile('RECEIVED', totalReceived)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatTile('LOCKED', lockedReceived)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatTile('UNLOCKED', unlockedReceived)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text('$value', style: AppTheme.display.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.label),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildRowItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Account Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(color: AppTheme.divider, height: 0, indent: 48),
          _buildRowItem(
            context,
            icon: Icons.notifications_none_outlined,
            title: 'Notification Preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(color: AppTheme.divider, height: 0, indent: 48),
          _buildRowItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTheme.body.copyWith(color: AppTheme.textBody),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: _buildRowItem(context, icon: icon, title: title, onTap: onTap),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildRowItem(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () => _showSignOutDialog(context, authProvider),
          ),
          const Divider(color: AppTheme.divider, height: 0, indent: 48),
          _buildRowItem(
            context,
            icon: Icons.delete_outline,
            title: 'Delete Account',
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion feature coming soon!'),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }
}
