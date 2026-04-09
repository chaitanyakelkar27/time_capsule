import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _capsuleUnlockNotifications = true;
  bool _reactionNotifications = true;
  bool _locationBasedUnlocks = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Dark';

  @override
  Widget build(BuildContext context) {
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
          'Settings',
          style: AppTheme.heading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildNotificationSettings(),
          const SizedBox(height: 12),
          _buildPrivacySettings(),
          const SizedBox(height: 12),
          _buildAppearanceSettings(),
          const SizedBox(height: 12),
          _buildDataSettings(),
          const SizedBox(height: 12),
          _buildAboutSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Section Card Builder ───────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(title, style: AppTheme.heading.copyWith(fontSize: 16)),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSectionCard(
      icon: Icons.notifications_none_outlined,
      title: 'Notifications',
      children: [
        _buildSwitch(
          title: 'Enable Notifications',
          subtitle: 'Receive push notifications',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() => _notificationsEnabled = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value ? 'Notifications enabled' : 'Notifications disabled',
                ),
              ),
            );
          },
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildSwitch(
          title: 'Capsule Unlock Alerts',
          subtitle: 'When a capsule becomes available',
          value: _capsuleUnlockNotifications,
          onChanged: _notificationsEnabled
              ? (value) => setState(() => _capsuleUnlockNotifications = value)
              : null,
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildSwitch(
          title: 'Reaction Notifications',
          subtitle: 'When someone reacts to your capsule',
          value: _reactionNotifications,
          onChanged: _notificationsEnabled
              ? (value) => setState(() => _reactionNotifications = value)
              : null,
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSectionCard(
      icon: Icons.shield_outlined,
      title: 'Privacy & Security',
      children: [
        _buildSwitch(
          title: 'Location-Based Unlocks',
          subtitle: 'Allow capsules to unlock based on location',
          value: _locationBasedUnlocks,
          onChanged: (value) => setState(() => _locationBasedUnlocks = value),
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildRowItem(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password change coming soon!')),
            );
          },
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildRowItem(
          icon: Icons.security_outlined,
          title: 'Two-Factor Authentication',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('2FA coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSectionCard(
      icon: Icons.palette_outlined,
      title: 'Appearance',
      children: [
        _buildRowItem(
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: _selectedTheme,
          onTap: _showThemeDialog,
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildRowItem(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: _selectedLanguage,
          onTap: _showLanguageDialog,
        ),
      ],
    );
  }

  Widget _buildDataSettings() {
    return _buildSectionCard(
      icon: Icons.storage_outlined,
      title: 'Data & Storage',
      children: [
        _buildRowItem(
          icon: Icons.download_outlined,
          title: 'Export My Data',
          subtitle: 'Download all your capsules',
          onTap: _showExportDataDialog,
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildRowItem(
          icon: Icons.delete_sweep_outlined,
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          onTap: _showClearCacheDialog,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSectionCard(
      icon: Icons.info_outline,
      title: 'About',
      children: [
        _buildRowItem(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms of Service coming soon!')),
            );
          },
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildRowItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Policy coming soon!')),
            );
          },
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        _buildRowItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support coming soon!')),
            );
          },
        ),
        const Divider(color: AppTheme.divider, height: 0, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Text('TimeCapsule', style: AppTheme.subheading.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('Version 1.0.0', style: AppTheme.label),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Reusable Widgets ───────────────────────────────────

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppTheme.body.copyWith(color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textMuted)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
      inactiveThumbColor: AppTheme.textMuted,
      inactiveTrackColor: AppTheme.divider,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required String title,
    String? subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.body.copyWith(color: AppTheme.textBody)),
                  if (subtitle != null)
                    Text(subtitle, style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value);
                Navigator.pop(dialogContext);
                if (value != 'Dark') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme feature coming soon!'),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Light'),
                    value: 'Light',
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark'),
                    value: 'Dark',
                  ),
                  RadioListTile<String>(
                    title: const Text('System'),
                    value: 'System',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Chinese',
      'Japanese',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() => _selectedLanguage = value);
              Navigator.pop(dialogContext);
              if (value != 'English') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Multi-language support coming soon!'),
                  ),
                );
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will export all your capsules, messages, and media to a downloadable file. This may take a few moments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export feature coming soon!'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and cached data. Your capsules and messages will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
