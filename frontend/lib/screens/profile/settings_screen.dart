import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildNotificationSettings(),
          const Divider(height: 32),
          _buildPrivacySettings(),
          const Divider(height: 32),
          _buildAppearanceSettings(),
          const Divider(height: 32),
          _buildDataSettings(),
          const Divider(height: 32),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive push notifications'),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value ? 'Notifications enabled' : 'Notifications disabled',
                ),
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Capsule Unlock Alerts'),
          subtitle: const Text('When a capsule becomes available'),
          value: _capsuleUnlockNotifications,
          onChanged: _notificationsEnabled
              ? (value) {
                  setState(() {
                    _capsuleUnlockNotifications = value;
                  });
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Reaction Notifications'),
          subtitle: const Text('When someone reacts to your capsule'),
          value: _reactionNotifications,
          onChanged: _notificationsEnabled
              ? (value) {
                  setState(() {
                    _reactionNotifications = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined, color: Colors.deepPurple),
              const SizedBox(width: 12),
              const Text(
                'Privacy & Security',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Location-Based Unlocks'),
          subtitle: const Text('Allow capsules to unlock based on location'),
          value: _locationBasedUnlocks,
          onChanged: (value) {
            setState(() {
              _locationBasedUnlocks = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password change coming soon!')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Two-Factor Authentication'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('2FA coming soon!')));
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.palette_outlined, color: Colors.deepPurple),
              const SizedBox(width: 12),
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Theme'),
          subtitle: Text(_selectedTheme),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showThemeDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: Text(_selectedLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showLanguageDialog();
          },
        ),
      ],
    );
  }

  Widget _buildDataSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.storage_outlined, color: Colors.deepPurple),
              const SizedBox(width: 12),
              const Text(
                'Data & Storage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export My Data'),
          subtitle: const Text('Download all your capsules'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showExportDataDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: const Text('Clear Cache'),
          subtitle: const Text('Free up storage space'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showClearCacheDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.deepPurple),
              const SizedBox(width: 12),
              const Text(
                'About',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms of Service coming soon!')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Policy coming soon!')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support coming soon!')),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Text(
                  'TimeCapsule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme feature coming soon!')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme feature coming soon!')),
                );
              },
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
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  if (value != 'English') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Multi-language support coming soon!'),
                      ),
                    );
                  }
                },
              );
            },
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
                  backgroundColor: Colors.orange,
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
                  backgroundColor: Colors.green,
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
