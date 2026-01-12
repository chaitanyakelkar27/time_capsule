import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/capsule_model.dart';

class CapsuleCard extends StatelessWidget {
  final CapsuleModel capsule;
  final bool isSent;
  final VoidCallback? onTap;

  const CapsuleCard({
    super.key,
    required this.capsule,
    required this.isSent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Lock Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: capsule.isLocked
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      capsule.isLocked ? Icons.lock : Icons.lock_open,
                      color: capsule.isLocked ? Colors.amber : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Recipient/Sender
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capsule.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSent
                              ? 'To: ${capsule.recipientName}'
                              : 'From: ${capsule.senderName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Type Badge
                  _buildTypeBadge(),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Unlock Info
              _buildUnlockInfo(context),

              const SizedBox(height: 8),

              // Status
              Row(
                children: [
                  Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(capsule.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    IconData icon;
    switch (capsule.type) {
      case 'image':
        icon = Icons.image;
        break;
      case 'video':
        icon = Icons.videocam;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        break;
      default:
        icon = Icons.text_fields;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 16, color: Colors.blue),
    );
  }

  Widget _buildUnlockInfo(BuildContext context) {
    if (!capsule.isLocked) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Unlocked on ${DateFormat('MMM dd, yyyy HH:mm').format(capsule.unlockedAt!)}',
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      );
    }

    if (capsule.isTimeLocked && capsule.unlockDate != null) {
      final timeLeft = capsule.timeUntilUnlock;
      if (timeLeft != null && timeLeft.isNegative) {
        return const Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.amber),
            SizedBox(width: 4),
            Text(
              'Ready to unlock!',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ],
        );
      } else if (timeLeft != null) {
        return Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Unlocks in ${_formatDuration(timeLeft)}',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        );
      }
    }

    if (capsule.isLocationLocked) {
      return const Row(
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.purple),
          SizedBox(width: 4),
          Text(
            'Unlocks at specific location',
            style: TextStyle(fontSize: 12, color: Colors.purple),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than a minute';
    }
  }

  IconData _getStatusIcon() {
    switch (capsule.status) {
      case 'unlocked':
        return Icons.lock_open;
      case 'reacted':
        return Icons.favorite;
      default:
        return Icons.lock;
    }
  }

  Color _getStatusColor() {
    switch (capsule.status) {
      case 'unlocked':
        return Colors.green;
      case 'reacted':
        return Colors.pink;
      default:
        return Colors.amber;
    }
  }

  String _getStatusText() {
    switch (capsule.status) {
      case 'unlocked':
        return 'Unlocked';
      case 'reacted':
        return 'Reacted';
      default:
        return 'Locked';
    }
  }
}
