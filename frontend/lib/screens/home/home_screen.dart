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
  int _activeTab = 0; // 0 = Sent, 1 = Received, 2 = Contacts
  String? _listeningUserId;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCapsuleListeners();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCapsuleListeners();
  }

  void _ensureCapsuleListeners() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final capsuleProvider = Provider.of<CapsuleProvider>(
      context,
      listen: false,
    );
    final userId = authProvider.user?.userId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    if (_listeningUserId == userId) {
      return;
    }

    _listeningUserId = userId;
    capsuleProvider.listenToSentCapsules(userId);
    capsuleProvider.listenToReceivedCapsules(userId);
    capsuleProvider.refreshContacts(userId);
  }

  Future<void> _reloadMainData() async {
    await _reloadMainDataWithOptions(showSnackBar: true);
  }

  Future<void> _reloadMainDataWithOptions({required bool showSnackBar}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final capsuleProvider = Provider.of<CapsuleProvider>(
      context,
      listen: false,
    );
    final userId = authProvider.user?.userId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    if (_isReloading) {
      return;
    }

    setState(() => _isReloading = true);

    try {
      // Restart listeners to force a fresh Firestore snapshot and reload contacts.
      capsuleProvider.listenToSentCapsules(userId);
      capsuleProvider.listenToReceivedCapsules(userId);
      await capsuleProvider.refreshContacts(userId);

      if (!mounted || !showSnackBar) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Main screen refreshed')));
    } catch (_) {
      if (!mounted || !showSnackBar) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            capsuleProvider.errorMessage ?? 'Failed to refresh main screen',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  Future<void> _handlePullToRefresh() async {
    await _reloadMainDataWithOptions(showSnackBar: false);
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

  Future<void> _showAddContactDialog(String? ownerUserId) async {
    if (ownerUserId == null || ownerUserId.isEmpty) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final contactIdController = TextEditingController();
    final displayNameController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text('Add Contact', style: AppTheme.subheading),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: contactIdController,
                  autofocus: true,
                  style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Contact user ID',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a contact user ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: displayNameController,
                  style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Display name (optional)',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(dialogContext).pop({
                  'userId': contactIdController.text.trim(),
                  'displayName': displayNameController.text.trim(),
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    contactIdController.dispose();
    displayNameController.dispose();

    if (result == null || (result['userId'] ?? '').isEmpty) {
      return;
    }

    await _addContactById(
      ownerUserId: ownerUserId,
      contactUserId: result['userId']!,
      displayName: result['displayName'] ?? '',
    );
  }

  Future<void> _addContactById({
    required String ownerUserId,
    required String contactUserId,
    required String displayName,
  }) async {
    final capsuleProvider = Provider.of<CapsuleProvider>(
      context,
      listen: false,
    );
    final contact = await capsuleProvider.addContactByUserId(
      ownerUserId: ownerUserId,
      contactUserId: contactUserId,
      displayName: displayName,
    );

    if (!mounted) return;

    if (contact != null) {
      final name = contact['displayName'] as String? ?? contactUserId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact added: $name'),
          backgroundColor: AppTheme.success,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(capsuleProvider.errorMessage ?? 'Failed to add contact'),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  Future<void> _confirmDeleteContact({
    required String ownerUserId,
    required String contactUserId,
    required String contactName,
  }) async {
    final normalizedContactId = contactUserId.trim();
    if (normalizedContactId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid contact. Please reload and try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Remove $contactName from your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;
    final capsuleProvider = Provider.of<CapsuleProvider>(
      context,
      listen: false,
    );
    final success = await capsuleProvider.deleteContact(
      ownerUserId: ownerUserId,
      contactUserId: normalizedContactId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Contact removed: $contactName'
              : capsuleProvider.errorMessage ?? 'Failed to remove contact',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
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
                  Text(
                    'TimeCapsule',
                    style: AppTheme.heading.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isReloading ? null : _reloadMainData,
                    tooltip: 'Reload',
                    icon: _isReloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    color: AppTheme.textSecondary,
                  ),
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
                    _buildToggle(
                      'Contacts (${capsuleProvider.contacts.length})',
                      2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Capsule List ─────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handlePullToRefresh,
                child: _activeTab == 2
                    ? _buildContactsList(
                        capsuleProvider,
                        authProvider.user?.userId,
                      )
                    : _activeTab == 0
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
            ),

            // ── New Capsule Button ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_activeTab == 2) {
                      _showAddContactDialog(authProvider.user?.userId);
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateCapsuleScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    _activeTab == 2 ? Icons.person_add_alt_1 : Icons.add,
                    size: 20,
                  ),
                  label: Text(_activeTab == 2 ? 'Add Contact' : 'New Capsule'),
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: Center(
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
            ),
          ),
        ],
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

  Widget _buildContactsList(
    CapsuleProvider capsuleProvider,
    String? ownerUserId,
  ) {
    final contacts = capsuleProvider.contacts;
    if (ownerUserId == null || ownerUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (contacts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 280,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'No contacts yet. Tap Add Contact below.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final rawContactUserId = contact['userId'];
        final contactUserId = rawContactUserId is String
            ? rawContactUserId.trim()
            : rawContactUserId?.toString().trim() ?? '';
        final rawContactName = contact['displayName'];
        final contactName =
            rawContactName is String && rawContactName.trim().isNotEmpty
            ? rawContactName.trim()
            : 'Contact';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactName,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contactUserId,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: contactUserId.isEmpty
                    ? null
                    : () => _confirmDeleteContact(
                        ownerUserId: ownerUserId,
                        contactUserId: contactUserId,
                        contactName: contactName,
                      ),
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                tooltip: 'Delete contact',
              ),
            ],
          ),
        );
      },
    );
  }
}
