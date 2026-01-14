import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../widgets/capsule_card.dart';
import '../capsule/create_capsule_screen.dart';
import '../capsule/capsule_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, locked, unlocked
  String _filterType = 'all'; // all, text, image, video

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
        title: const Text('TimeCapsule'),
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
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
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
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilter(),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sent Capsules
                _buildCapsuleList(
                  _filterCapsules(capsuleProvider.sentCapsules),
                  isSent: true,
                  emptyMessage:
                      'No sent capsules yet.\nCreate your first time capsule!',
                ),
                // Received Capsules
                _buildCapsuleList(
                  _filterCapsules(capsuleProvider.receivedCapsules),
                  isSent: false,
                  emptyMessage:
                      'No received capsules yet.\nWaiting for someone to send you a memory!',
                ),
              ],
            ),
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search capsules...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Status',
                  selected: _filterStatus == 'all',
                  onSelected: () => setState(() => _filterStatus = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Locked',
                  icon: Icons.lock,
                  selected: _filterStatus == 'locked',
                  onSelected: () => setState(() => _filterStatus = 'locked'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Unlocked',
                  icon: Icons.lock_open,
                  selected: _filterStatus == 'unlocked',
                  onSelected: () => setState(() => _filterStatus = 'unlocked'),
                ),
                const SizedBox(width: 16),
                _buildFilterChip(
                  label: 'All Types',
                  selected: _filterType == 'all',
                  onSelected: () => setState(() => _filterType = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Text',
                  icon: Icons.text_fields,
                  selected: _filterType == 'text',
                  onSelected: () => setState(() => _filterType = 'text'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Image',
                  icon: Icons.image,
                  selected: _filterType == 'image',
                  onSelected: () => setState(() => _filterType = 'image'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Video',
                  icon: Icons.video_library,
                  selected: _filterType == 'video',
                  onSelected: () => setState(() => _filterType = 'video'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 4)],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.deepPurple.withValues(alpha: 0.3),
      checkmarkColor: Colors.deepPurple,
    );
  }

  List _filterCapsules(List capsules) {
    return capsules.where((capsule) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final titleMatch = capsule.title.toLowerCase().contains(_searchQuery);
        final senderMatch = capsule.senderName.toLowerCase().contains(
          _searchQuery,
        );
        final recipientMatch = capsule.recipientName.toLowerCase().contains(
          _searchQuery,
        );

        if (!titleMatch && !senderMatch && !recipientMatch) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus == 'locked' && !capsule.isLocked) {
        return false;
      }
      if (_filterStatus == 'unlocked' && capsule.isLocked) {
        return false;
      }

      // Type filter
      if (_filterType != 'all' && capsule.type != _filterType) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildCapsuleList(
    List capsules, {
    required bool isSent,
    required String emptyMessage,
  }) {
    if (capsules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use image instead of icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(
                      isSent
                          ? 'assets/images/sent_empty.png'
                          : 'assets/images/received_empty.png',
                    ),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: Center(
                  child: Icon(
                    isSent ? Icons.send_rounded : Icons.inbox_rounded,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
            ],
          ),
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
