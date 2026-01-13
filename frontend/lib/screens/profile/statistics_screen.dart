import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/capsule_provider.dart';
import '../../models/capsule_model.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final allCapsules = [
      ...capsuleProvider.sentCapsules,
      ...capsuleProvider.receivedCapsules,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: allCapsules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No data yet!\nCreate some capsules to see statistics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(capsuleProvider),
                  const SizedBox(height: 24),
                  _buildTypeBreakdown(allCapsules),
                  const SizedBox(height: 24),
                  _buildStatusBreakdown(capsuleProvider),
                  const SizedBox(height: 24),
                  _buildUpcomingUnlocks(allCapsules),
                  const SizedBox(height: 24),
                  _buildTopContacts(capsuleProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewSection(CapsuleProvider capsuleProvider) {
    final totalCapsules =
        capsuleProvider.sentCapsules.length +
        capsuleProvider.receivedCapsules.length;
    final totalUnlocked =
        capsuleProvider.receivedCapsules.where((c) => !c.isLocked).length +
        capsuleProvider.sentCapsules.where((c) => !c.isLocked).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Capsules',
                    totalCapsules.toString(),
                    Icons.widgets,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Unlocked',
                    totalUnlocked.toString(),
                    Icons.lock_open,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Sent',
                    capsuleProvider.sentCapsules.length.toString(),
                    Icons.send,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Received',
                    capsuleProvider.receivedCapsules.length.toString(),
                    Icons.inbox,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildTypeBreakdown(List<CapsuleModel> allCapsules) {
    final textCount = allCapsules.where((c) => c.type == 'text').length;
    final imageCount = allCapsules.where((c) => c.type == 'image').length;
    final videoCount = allCapsules.where((c) => c.type == 'video').length;
    final total = allCapsules.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Capsule Types',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTypeBar('Text', textCount, total, Colors.blue),
            const SizedBox(height: 12),
            _buildTypeBar('Image', imageCount, total, Colors.green),
            const SizedBox(height: 12),
            _buildTypeBar('Video', videoCount, total, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBar(String label, int count, int total, Color color) {
    final percentage = total > 0
        ? (count / total * 100).toStringAsFixed(0)
        : '0';
    final progress = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '$count ($percentage%)',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(CapsuleProvider capsuleProvider) {
    final received = capsuleProvider.receivedCapsules;

    final lockedReceived = received.where((c) => c.isLocked).length;
    final unlockedReceived = received.where((c) => !c.isLocked).length;
    final withReactions = received.where((c) => c.hasReaction).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Received Capsules Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Locked',
                    lockedReceived.toString(),
                    Icons.lock,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    'Unlocked',
                    unlockedReceived.toString(),
                    Icons.lock_open,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    'Reactions',
                    withReactions.toString(),
                    Icons.favorite,
                    Colors.pink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingUnlocks(List<CapsuleModel> allCapsules) {
    final lockedWithDate =
        allCapsules.where((c) => c.isLocked && c.unlockDate != null).toList()
          ..sort((a, b) => a.unlockDate!.compareTo(b.unlockDate!));

    final upcoming = lockedWithDate.take(5).toList();

    if (upcoming.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Unlocks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'No time-locked capsules scheduled',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Unlocks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...upcoming.map((capsule) => _buildUpcomingUnlockItem(capsule)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingUnlockItem(CapsuleModel capsule) {
    final daysUntil = capsule.unlockDate!.difference(DateTime.now()).inDays;
    final dateStr = DateFormat('MMM dd, yyyy').format(capsule.unlockDate!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: daysUntil <= 7 ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysUntil <= 7
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysUntil == 0
                  ? 'Today'
                  : daysUntil == 1
                  ? '1 day'
                  : '$daysUntil days',
              style: TextStyle(
                fontSize: 12,
                color: daysUntil <= 7 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContacts(CapsuleProvider capsuleProvider) {
    final Map<String, int> contactCounts = {};

    // Count sent capsules
    for (var capsule in capsuleProvider.sentCapsules) {
      contactCounts[capsule.recipientName] =
          (contactCounts[capsule.recipientName] ?? 0) + 1;
    }

    // Count received capsules
    for (var capsule in capsuleProvider.receivedCapsules) {
      contactCounts[capsule.senderName] =
          (contactCounts[capsule.senderName] ?? 0) + 1;
    }

    final sortedContacts = contactCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topContacts = sortedContacts.take(5).toList();

    if (topContacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Top Contacts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topContacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;
              return _buildTopContactItem(
                index + 1,
                contact.key,
                contact.value,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopContactItem(int rank, String name, int count) {
    final color = rank == 1
        ? Colors.amber
        : rank == 2
        ? Colors.grey
        : rank == 3
        ? Colors.brown
        : Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count capsules',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
