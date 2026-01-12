import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/capsule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';

class CapsuleDetailScreen extends StatefulWidget {
  final CapsuleModel capsule;
  final bool isSent;

  const CapsuleDetailScreen({
    super.key,
    required this.capsule,
    required this.isSent,
  });

  @override
  State<CapsuleDetailScreen> createState() => _CapsuleDetailScreenState();
}

class _CapsuleDetailScreenState extends State<CapsuleDetailScreen> {
  Timer? _countdownTimer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    if (widget.capsule.isLocked && widget.capsule.isTimeLocked) {
      _updateTimeRemaining();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTimeRemaining();
      });
    }
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = widget.capsule.timeUntilUnlock;

      // Check if time has passed
      if (_timeRemaining != null && _timeRemaining!.isNegative) {
        _countdownTimer?.cancel();
        // Optionally trigger unlock check
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final isRecipient = authProvider.user?.userId == widget.capsule.recipientId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.capsule.title),
        actions: [
          if (widget.isSent)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, capsuleProvider),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            _buildStatusHeader(),

            const SizedBox(height: 16),

            // Capsule Info
            _buildInfoSection(),

            const SizedBox(height: 24),

            // Content Area
            if (widget.capsule.isLocked)
              _buildLockedContent()
            else
              _buildUnlockedContent(),

            const SizedBox(height: 24),

            // Action Buttons
            if (!widget.capsule.isLocked && isRecipient)
              _buildActionButtons(capsuleProvider),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (widget.capsule.status == 'reacted') {
      statusColor = Colors.pink;
      statusIcon = Icons.favorite;
      statusText = 'REACTED';
    } else if (widget.capsule.isLocked) {
      statusColor = Colors.amber;
      statusIcon = Icons.lock;
      statusText = 'LOCKED';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.lock_open;
      statusText = 'UNLOCKED';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.3),
            statusColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 64, color: statusColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 2,
            ),
          ),
          if (widget.capsule.isLocked && _timeRemaining != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  const Text(
                    'Time Remaining',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_timeRemaining!),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline,
            widget.isSent ? 'To' : 'From',
            widget.isSent
                ? widget.capsule.recipientName
                : widget.capsule.senderName,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.category_outlined,
            'Type',
            widget.capsule.type.toUpperCase(),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.calendar_today,
            'Created',
            DateFormat('MMM dd, yyyy • HH:mm').format(widget.capsule.createdAt),
          ),
          if (widget.capsule.unlockDate != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Unlocks On',
              DateFormat(
                'MMM dd, yyyy • HH:mm',
              ).format(widget.capsule.unlockDate!),
            ),
          ],
          if (widget.capsule.isLocationLocked) ...[
            const Divider(height: 24),
            _buildInfoRow(
              Icons.location_on,
              'Unlock Location',
              'GPS coordinates required',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_clock, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'This Capsule is Locked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getLockedMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (widget.capsule.isTimeLocked &&
              _timeRemaining != null &&
              _timeRemaining!.isNegative)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: () => _checkUnlock(),
                icon: const Icon(Icons.refresh),
                label: const Text('Check if Unlocked'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnlockedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unlocked banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capsule Unlocked!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (widget.capsule.unlockedAt != null)
                        Text(
                          'Opened on ${DateFormat('MMM dd, yyyy').format(widget.capsule.unlockedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content
          if (widget.capsule.type == 'text') _buildTextContent(),

          // Media content (images/videos) - placeholder for now
          if (widget.capsule.type == 'image' || widget.capsule.type == 'video')
            _buildMediaPlaceholder(),

          // Reaction video if exists
          if (widget.capsule.reactionVideoUrl != null) ...[
            const SizedBox(height: 32),
            _buildReactionSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.blue[300]),
                const SizedBox(width: 8),
                const Text(
                  'Message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.capsule.message ?? 'No message',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder() {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.capsule.type == 'image'
                  ? Icons.image_outlined
                  : Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Media content coming soon',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (widget.capsule.mediaUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'URL: ${widget.capsule.mediaUrl}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionSection() {
    return Card(
      color: Colors.pink.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink),
                const SizedBox(width: 8),
                const Text(
                  'Reaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'Reaction video player coming soon',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    if (widget.capsule.reactionRecordedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Recorded on ${DateFormat('MMM dd, yyyy').format(widget.capsule.reactionRecordedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(CapsuleProvider capsuleProvider) {
    if (widget.capsule.status == 'reacted') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          color: Colors.pink.withValues(alpha: 0.2),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.pink),
                SizedBox(width: 8),
                Text(
                  'You\'ve already recorded a reaction',
                  style: TextStyle(color: Colors.pink),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _recordReaction(),
              icon: const Icon(Icons.videocam),
              label: const Text('Record Reaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _skipReaction(capsuleProvider),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  String _getLockedMessage() {
    if (widget.capsule.unlockType == 'both') {
      return 'This capsule requires both the correct time and location to unlock.';
    } else if (widget.capsule.isTimeLocked) {
      if (_timeRemaining != null && !_timeRemaining!.isNegative) {
        return 'This capsule will unlock when the time comes. Check back later!';
      } else {
        return 'The unlock time has passed. The capsule should unlock soon!';
      }
    } else if (widget.capsule.isLocationLocked) {
      return 'This capsule will unlock when you reach the specified location.';
    }
    return 'This capsule is locked.';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Ready to unlock!';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else if (minutes > 0) {
      return '$minutes minutes, $seconds seconds';
    } else {
      return '$seconds seconds';
    }
  }

  void _checkUnlock() {
    // TODO: Implement actual unlock check with cloud function
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Checking unlock status... (Cloud Functions coming soon)',
        ),
      ),
    );
  }

  void _recordReaction() {
    // TODO: Implement reaction recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reaction recording coming soon!'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  Future<void> _skipReaction(CapsuleProvider capsuleProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Reaction?'),
        content: const Text(
          'You can always record a reaction later from this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CapsuleProvider capsuleProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Capsule?'),
        content: const Text(
          'Are you sure you want to delete this capsule? This action cannot be undone.',
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

    if (confirmed == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete capsule
      await capsuleProvider.deleteCapsule(widget.capsule.capsuleId);

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Close detail screen
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capsule deleted successfully')),
        );
      }
    }
  }
}
