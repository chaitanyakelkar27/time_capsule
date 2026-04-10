import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/capsule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

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
  final _locationService = LocationService();
  final _storageService = StorageService();
  VideoPlayerController? _videoController;
  bool _isCheckingLocation = false;
  bool _isRecordingReaction = false;
  double? _distanceToUnlock;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    if (widget.capsule.videoUrl != null &&
        !widget.capsule.isEffectivelyLocked) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.capsule.videoUrl!),
      );
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    if (widget.capsule.isEffectivelyLocked && widget.capsule.isTimeLocked) {
      _updateTimeRemaining();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTimeRemaining();
      });
    }
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = widget.capsule.timeUntilUnlock;
      if (_timeRemaining != null && _timeRemaining!.isNegative) {
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final isRecipient = authProvider.user?.userId == widget.capsule.recipientId;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.capsule.isEffectivelyLocked)
            IconButton(
              icon: const Icon(
                Icons.share_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
          if (widget.isSent)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => _confirmDelete(context, capsuleProvider),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status Label ───────────────────────
              _buildStatusLabel(),
              const SizedBox(height: 8),

              // ── Title ─────────────────────────────
              Text(
                widget.capsule.title,
                style: AppTheme.display.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 20),

              // ── Countdown (locked time-based) ─────
              if (widget.capsule.isEffectivelyLocked &&
                  widget.capsule.isTimeLocked &&
                  _timeRemaining != null &&
                  !_timeRemaining!.isNegative)
                _buildCountdownTiles(),

              if (widget.capsule.isEffectivelyLocked &&
                  widget.capsule.isTimeLocked &&
                  _timeRemaining != null &&
                  !_timeRemaining!.isNegative)
                const SizedBox(height: 24),

              // ── Info Section ───────────────────────
              _buildInfoSection(),
              const SizedBox(height: 20),

              // ── Content Area ───────────────────────
              if (widget.capsule.isEffectivelyLocked)
                _buildLockedContent()
              else
                _buildUnlockedContent(),

              const SizedBox(height: 24),

              // ── Action Buttons ─────────────────────
              if (!widget.capsule.isEffectivelyLocked && isRecipient)
                _buildActionButtons(capsuleProvider),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status Label ─────────────────────────────────────
  Widget _buildStatusLabel() {
    final isLocked = widget.capsule.isEffectivelyLocked;
    final color = isLocked ? AppTheme.statusLocked : AppTheme.statusUnlocked;
    final text = isLocked ? 'LOCKED' : 'UNLOCKED';

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: AppTheme.label.copyWith(color: color)),
      ],
    );
  }

  // ── Countdown Tiles ──────────────────────────────────
  Widget _buildCountdownTiles() {
    final d = _timeRemaining!;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    return Row(
      children: [
        _buildCountTile(days.toString().padLeft(2, '0'), 'DAYS'),
        const SizedBox(width: 8),
        _buildCountTile(hours.toString().padLeft(2, '0'), 'HRS'),
        const SizedBox(width: 8),
        _buildCountTile(minutes.toString().padLeft(2, '0'), 'MIN'),
        const SizedBox(width: 8),
        _buildCountTile(seconds.toString().padLeft(2, '0'), 'SEC'),
      ],
    );
  }

  Widget _buildCountTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.label.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Info Section ─────────────────────────────────────
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline,
            widget.isSent ? 'To' : 'From',
            widget.isSent
                ? widget.capsule.recipientName
                : widget.capsule.senderName,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppTheme.divider),
          ),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Created',
            DateFormat('MMM dd, yyyy').format(widget.capsule.createdAt),
          ),
          if (widget.capsule.unlockDate != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppTheme.divider),
            ),
            _buildInfoRow(
              Icons.schedule,
              'Unlock Date',
              DateFormat(
                'MMM dd, yyyy - hh:mm a',
              ).format(widget.capsule.unlockDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 12),
        Text(label, style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Locked Content ───────────────────────────────────
  Widget _buildLockedContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_outlined, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'This Capsule is Locked',
            style: AppTheme.heading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            _getLockedMessage(),
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(color: AppTheme.textMuted),
          ),
          if (widget.capsule.isLocationLocked) ...[
            const SizedBox(height: 20),
            _buildLocationUnlockCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationUnlockCard() {
    final withinRadius =
        _distanceToUnlock != null &&
        _distanceToUnlock! <= (widget.capsule.unlockRadius ?? 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.scaffold,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(
          color: withinRadius ? AppTheme.success : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Location Required',
                style: AppTheme.subheading.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You must be within ${widget.capsule.unlockRadius?.toInt() ?? 100}m of the unlock location.',
            style: AppTheme.body.copyWith(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          if (_distanceToUnlock != null) ...[
            const SizedBox(height: 10),
            Text(
              'Current distance: ${_distanceToUnlock! < 1000 ? "${_distanceToUnlock!.toStringAsFixed(0)}m" : "${(_distanceToUnlock! / 1000).toStringAsFixed(2)}km"}',
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w600,
                color: withinRadius ? AppTheme.success : AppTheme.warning,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isCheckingLocation ? null : _checkLocationUnlock,
            icon: _isCheckingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(_isCheckingLocation ? 'Checking...' : 'Check Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocationUnlock() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position == null || widget.capsule.unlockLocation == null) {
        throw Exception('Location not available');
      }

      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        widget.capsule.unlockLocation!.latitude,
        widget.capsule.unlockLocation!.longitude,
      );

      setState(() {
        _distanceToUnlock = distance;
      });

      final unlockRadius = widget.capsule.unlockRadius ?? 100;
      if (distance <= unlockRadius) {
        await _unlockCapsule();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capsule unlocked! You are at the right location.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You are ${distance < 1000 ? "${distance.toStringAsFixed(0)}m" : "${(distance / 1000).toStringAsFixed(2)}km"} away. Get closer to unlock!',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error checking location: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
        });
      }
    }
  }

  Future<void> _unlockCapsule() async {
    await Provider.of<CapsuleProvider>(
      context,
      listen: false,
    ).unlockCapsule(widget.capsule.capsuleId);

    if (mounted) {
      setState(() {});
    }
  }

  // ── Unlocked Content ─────────────────────────────────
  Widget _buildUnlockedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.capsule.imageUrl != null) _buildImageContent(),
        if (widget.capsule.videoUrl != null) _buildVideoContent(),
        if (widget.capsule.message != null &&
            widget.capsule.message!.isNotEmpty)
          _buildTextContent(),
        if (widget.capsule.recipientId ==
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).user?.userId &&
            widget.capsule.reactionVideoUrl == null) ...[
          const SizedBox(height: 20),
          _buildRecordReactionButton(),
        ],
        if (widget.capsule.reactionVideoUrl != null) ...[
          const SizedBox(height: 24),
          _buildReactionSection(),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: CachedNetworkImage(
          imageUrl: widget.capsule.imageUrl!,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 240,
            color: AppTheme.cardBg,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusCard),
              ),
              child: Container(
                height: 240,
                color: Colors.black,
                child:
                    _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading video...',
                              style: AppTheme.body.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.videocam_outlined,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Video',
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_videoController != null &&
                      _videoController!.value.isInitialized)
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: AppTheme.textPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Container(
      width: double.infinity,
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
              const Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Message', style: AppTheme.subheading),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.capsule.message ?? 'No message',
            style: AppTheme.body.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordReactionButton() {
    return OutlinedButton.icon(
      onPressed: _isRecordingReaction ? null : _recordReaction,
      icon: _isRecordingReaction
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            )
          : const Icon(Icons.mic_outlined, size: 18, color: AppTheme.primary),
      label: Text(
        _isRecordingReaction ? 'Uploading...' : 'Record Reaction',
        style: AppTheme.body.copyWith(color: AppTheme.primary),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Future<void> _recordReaction() async {
    setState(() {
      _isRecordingReaction = true;
    });

    try {
      final videoFile = await _storageService.recordVideoFromCamera();

      if (videoFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recording cancelled')));
        }
        return;
      }

      final reactionUrl = await _storageService.uploadReactionVideo(
        file: videoFile,
        capsuleId: widget.capsule.capsuleId,
      );

      if (reactionUrl != null && mounted) {
        await Provider.of<CapsuleProvider>(
          context,
          listen: false,
        ).addReaction(widget.capsule.capsuleId, reactionUrl);
      } else {
        throw Exception('Failed to upload reaction video');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reaction video uploaded successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record reaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingReaction = false;
        });
      }
    }
  }

  Widget _buildReactionSection() {
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
              const Icon(
                Icons.favorite_outline,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Reaction', style: AppTheme.subheading),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.scaffold,
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videocam_outlined,
                    size: 36,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reaction video player coming soon',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  if (widget.capsule.reactionRecordedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Recorded on ${DateFormat('MMM dd, yyyy').format(widget.capsule.reactionRecordedAt!)}',
                        style: AppTheme.label,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ───────────────────────────────────
  Widget _buildActionButtons(CapsuleProvider capsuleProvider) {
    if (widget.capsule.status == 'reacted') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "You've already recorded a reaction",
              style: AppTheme.body.copyWith(color: AppTheme.success),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _recordReaction(),
          icon: const Icon(Icons.videocam_outlined, size: 18),
          label: const Text('Record Reaction'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _skipReaction(capsuleProvider),
          child: Text(
            'Skip for now',
            style: AppTheme.body.copyWith(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  String _getLockedMessage() {
    if (widget.capsule.isTimeLocked && widget.capsule.isLocationLocked) {
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      bool loadingOpen = false;

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        );
        loadingOpen = true;

        final success = await capsuleProvider.deleteCapsule(
          widget.capsule.capsuleId,
        );

        if (!context.mounted) return;

        if (loadingOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingOpen = false;
        }

        if (!success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                capsuleProvider.errorMessage ?? 'Failed to delete capsule',
              ),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }

        // Pop detail screen only once to return to home list.
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Capsule deleted successfully')),
        );
      } catch (e) {
        if (!context.mounted) return;

        if (loadingOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingOpen = false;
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete capsule: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
