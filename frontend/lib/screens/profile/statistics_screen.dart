import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/capsule_provider.dart';
import '../../models/capsule_model.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Statistics',
          style: AppTheme.heading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: allCapsules.isEmpty
          ? Center(
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
                    child: const Icon(
                      Icons.bar_chart_outlined,
                      size: 32,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data yet!',
                    style: AppTheme.heading.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create some capsules to see statistics.',
                    style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(capsuleProvider),
                  const SizedBox(height: 12),
                  _buildTypeBreakdown(allCapsules),
                  const SizedBox(height: 12),
                  _buildStatusBreakdown(capsuleProvider),
                  const SizedBox(height: 12),
                  _buildUpcomingUnlocks(allCapsules),
                  const SizedBox(height: 12),
                  _buildTopContacts(capsuleProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.heading.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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

    return _buildSectionCard(
      icon: Icons.analytics_outlined,
      title: 'Overview',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Capsules',
                  totalCapsules.toString(),
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Unlocked',
                  totalUnlocked.toString(),
                  AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Sent',
                  capsuleProvider.sentCapsules.length.toString(),
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Received',
                  capsuleProvider.receivedCapsules.length.toString(),
                  AppTheme.statusScheduled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.scaffold,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.display.copyWith(fontSize: 28, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.label),
        ],
      ),
    );
  }

  Widget _buildTypeBreakdown(List<CapsuleModel> allCapsules) {
    final textCount = allCapsules.where((c) => c.type == 'text').length;
    final imageCount = allCapsules.where((c) => c.type == 'image').length;
    final videoCount = allCapsules.where((c) => c.type == 'video').length;
    final total = allCapsules.length;

    return _buildSectionCard(
      icon: Icons.donut_large_outlined,
      title: 'Capsule Types',
      child: Column(
        children: [
          _buildTypeBar('Text', textCount, total, AppTheme.primary),
          const SizedBox(height: 12),
          _buildTypeBar('Image', imageCount, total, AppTheme.success),
          const SizedBox(height: 12),
          _buildTypeBar('Video', videoCount, total, AppTheme.warning),
        ],
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
            Text(label, style: AppTheme.body.copyWith(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            Text(
              '$count ($percentage%)',
              style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
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

    return _buildSectionCard(
      icon: Icons.info_outline,
      title: 'Received Status',
      child: Row(
        children: [
          Expanded(
            child: _buildStatusTile('Locked', lockedReceived.toString(), AppTheme.warning),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusTile('Unlocked', unlockedReceived.toString(), AppTheme.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusTile('Reactions', withReactions.toString(), AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.scaffold,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.display.copyWith(fontSize: 24, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.label,
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

    return _buildSectionCard(
      icon: Icons.schedule_outlined,
      title: 'Upcoming Unlocks',
      child: upcoming.isEmpty
          ? Text(
              'No time-locked capsules scheduled',
              style: AppTheme.body.copyWith(color: AppTheme.textMuted),
            )
          : Column(
              children: upcoming.map((capsule) => _buildUpcomingItem(capsule)).toList(),
            ),
    );
  }

  Widget _buildUpcomingItem(CapsuleModel capsule) {
    final daysUntil = capsule.unlockDate!.difference(DateTime.now()).inDays;
    final dateStr = DateFormat('MMM dd, yyyy').format(capsule.unlockDate!);
    final color = daysUntil <= 7 ? AppTheme.success : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
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
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(dateStr, style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              daysUntil == 0
                  ? 'Today'
                  : daysUntil == 1
                  ? '1 day'
                  : '$daysUntil days',
              style: AppTheme.label.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContacts(CapsuleProvider capsuleProvider) {
    final Map<String, int> contactCounts = {};

    for (var capsule in capsuleProvider.sentCapsules) {
      contactCounts[capsule.recipientName] =
          (contactCounts[capsule.recipientName] ?? 0) + 1;
    }

    for (var capsule in capsuleProvider.receivedCapsules) {
      contactCounts[capsule.senderName] =
          (contactCounts[capsule.senderName] ?? 0) + 1;
    }

    final sortedContacts = contactCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topContacts = sortedContacts.take(5).toList();

    if (topContacts.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.people_outline,
      title: 'Top Contacts',
      child: Column(
        children: topContacts
            .asMap()
            .entries
            .map((entry) => _buildContactItem(
                  entry.key + 1,
                  entry.value.key,
                  entry.value.value,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildContactItem(int rank, String name, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTheme.label.copyWith(
                  color: rank <= 3 ? AppTheme.primary : AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              '$count capsules',
              style: AppTheme.label.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
