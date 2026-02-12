import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/capsule_model.dart';

class AnimatedCapsuleCard extends StatefulWidget {
  final CapsuleModel capsule;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const AnimatedCapsuleCard({
    super.key,
    required this.capsule,
    this.onTap,
    this.onDelete,
    this.onShare,
  });

  @override
  State<AnimatedCapsuleCard> createState() => _AnimatedCapsuleCardState();
}

class _AnimatedCapsuleCardState extends State<AnimatedCapsuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _unlockController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _justUnlocked = false;

  @override
  void initState() {
    super.initState();
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _unlockController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _unlockController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedCapsuleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if capsule just got unlocked
    if (oldWidget.capsule.isLocked &&
        !widget.capsule.isLocked &&
        !_justUnlocked) {
      _justUnlocked = true;
      _playUnlockAnimation();
    }
  }

  void _playUnlockAnimation() {
    _unlockController.forward().then((_) {
      _unlockController.reverse();
    });
  }

  @override
  void dispose() {
    _unlockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.capsule.capsuleId),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green,
        icon: Icons.share,
        text: 'Share',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        text: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete action
          return await _showDeleteConfirmation();
        } else if (direction == DismissDirection.startToEnd) {
          // Share action
          widget.onShare?.call();
          return false; // Don't dismiss
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete?.call();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    if (widget.capsule.isLocked) {
      return _buildLockedCard();
    } else {
      return _buildUnlockedCard();
    }
  }

  Widget _buildLockedCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        period: const Duration(milliseconds: 1500),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.capsule.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildCapsuleTypeIcon(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Locked',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 8),
                _buildUnlockInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_open, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.capsule.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildCapsuleTypeIcon(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.capsule.message ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[300]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'From: ${widget.capsule.senderName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        widget.capsule.reactionVideoUrl != null ? '1' : '0',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleTypeIcon() {
    IconData icon;
    Color color;

    switch (widget.capsule.type) {
      case 'image':
        icon = Icons.image;
        color = Colors.blue;
        break;
      case 'video':
        icon = Icons.videocam;
        color = Colors.purple;
        break;
      default:
        icon = Icons.text_fields;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildUnlockInfo() {
    final unlockDate = widget.capsule.unlockDate;

    if (unlockDate != null) {
      final now = DateTime.now();
      final duration = unlockDate.difference(now);

      String timeRemaining;
      if (duration.inDays > 0) {
        timeRemaining =
            '${duration.inDays}d ${duration.inHours % 24}h remaining';
      } else if (duration.inHours > 0) {
        timeRemaining =
            '${duration.inHours}h ${duration.inMinutes % 60}m remaining';
      } else if (duration.inMinutes > 0) {
        timeRemaining = '${duration.inMinutes}m remaining';
      } else {
        timeRemaining = 'Unlocking soon...';
      }

      return Row(
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            timeRemaining,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      );
    } else if (widget.capsule.unlockLocation != null) {
      return Row(
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Unlock at location',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Capsule'),
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
        ) ??
        false;
  }
}
