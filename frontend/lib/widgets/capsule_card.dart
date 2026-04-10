import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/capsule_model.dart';
import '../theme/app_theme.dart';

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
    final statusColor = _statusColor();
    final statusIcon = _statusIcon();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.divider, width: 1),
            ),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capsule.title,
                        style: AppTheme.subheading.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSent
                            ? 'To: ${capsule.recipientName}'
                            : 'From: ${capsule.senderName}',
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildUnlockChip(),
                    ],
                  ),
                ),

                // Trailing icon
                Icon(statusIcon, color: statusColor, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor() {
    if (capsule.status == 'reacted') return AppTheme.primary;
    return capsule.isEffectivelyLocked
        ? AppTheme.statusLocked
        : AppTheme.statusUnlocked;
  }

  IconData _statusIcon() {
    if (!capsule.isEffectivelyLocked) return Icons.check_circle_outline;
    return Icons.lock_outline;
  }

  Widget _buildUnlockChip() {
    final label = _buildUnlockLabel();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.divider,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTheme.label.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildUnlockLabel() {
    if (!capsule.isEffectivelyLocked) {
      if (capsule.unlockedAt != null) {
        return 'UNLOCKED ${DateFormat('MMM dd, yyyy').format(capsule.unlockedAt!)}';
      }
      return 'UNLOCKED';
    }

    if (capsule.isTimeLocked && capsule.unlockDate != null) {
      return 'UNLOCK ${DateFormat('MMM dd, yyyy').format(capsule.unlockDate!)}';
    }

    if (capsule.isLocationLocked) {
      return 'UNLOCK AT LOCATION';
    }

    return 'CREATED ${DateFormat('MMM dd, yyyy').format(capsule.createdAt)}';
  }
}
