import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/capsule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';

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
    if (widget.capsule.videoUrl != null && !widget.capsule.isLocked) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildActionButtons(capsuleProvider),
                ),
            ],
          ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replace icon with image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/images/lock_icon.png'),
                fit: BoxFit.cover,
                onError: null,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.lock_clock_rounded,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
          ),
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
          Flexible(
            child: Text(
              _getLockedMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          if (widget.capsule.isTimeLocked &&
              _timeRemaining != null &&
              !_timeRemaining!.isNegative)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _buildCountdownCard(),
            ),
          if (widget.capsule.isLocationLocked) ...[
            const SizedBox(height: 16),
            _buildLocationUnlockCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    if (_timeRemaining == null) return const SizedBox.shrink();

    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, color: Colors.orange[300]),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Time Remaining',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_timeRemaining!),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationUnlockCard() {
    return Card(
      color:
          _distanceToUnlock != null &&
              _distanceToUnlock! <= (widget.capsule.unlockRadius ?? 100)
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.orange[300]),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Location Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You must be within ${widget.capsule.unlockRadius?.toInt() ?? 100}m of the unlock location.',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            if (_distanceToUnlock != null) ...[
              const SizedBox(height: 12),
              Text(
                'Current distance: ${_distanceToUnlock! < 1000 ? "${_distanceToUnlock!.toStringAsFixed(0)}m" : "${(_distanceToUnlock! / 1000).toStringAsFixed(2)}km"}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      _distanceToUnlock! <= (widget.capsule.unlockRadius ?? 100)
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isCheckingLocation ? null : _checkLocationUnlock,
              icon: _isCheckingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isCheckingLocation ? 'Checking...' : 'Check Location',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _distanceToUnlock != null &&
                        _distanceToUnlock! <=
                            (widget.capsule.unlockRadius ?? 100)
                    ? Colors.green
                    : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkLocationUnlock() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();

      if (position == null || widget.capsule.unlockLocation == null) {
        throw Exception('Location not available');
      }

      // Calculate distance
      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        widget.capsule.unlockLocation!.latitude,
        widget.capsule.unlockLocation!.longitude,
      );

      setState(() {
        _distanceToUnlock = distance;
      });

      // Check if within radius
      final unlockRadius = widget.capsule.unlockRadius ?? 100;
      if (distance <= unlockRadius) {
        // Unlock the capsule
        await _unlockCapsule();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capsule unlocked! You are at the right location.'),
              backgroundColor: Colors.green,
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

    // Refresh the screen
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildUnlockedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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

          // Media content (image or video)
          if (widget.capsule.imageUrl != null) _buildImageContent(),
          if (widget.capsule.videoUrl != null) _buildVideoContent(),

          // Text message (caption for media types or standalone message)
          if (widget.capsule.message != null &&
              widget.capsule.message!.isNotEmpty)
            _buildTextContent(),

          // Reaction recording button for recipients
          if (widget.capsule.recipientId ==
                  Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).user?.userId &&
              widget.capsule.reactionVideoUrl == null) ...[
            const SizedBox(height: 24),
            _buildRecordReactionButton(),
          ],

          // Reaction video if exists
          if (widget.capsule.reactionVideoUrl != null) ...[
            const SizedBox(height: 32),
            _buildReactionSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: widget.capsule.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 300,
                color: Colors.grey.withValues(alpha: 0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.grey.withValues(alpha: 0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Image',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 300,
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
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading video...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_library,
                      color: Colors.blue[300],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Video',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  Widget _buildRecordReactionButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.videocam, color: Colors.purple[300]),
                const SizedBox(width: 8),
                const Text(
                  'Record Your Reaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Capture your reaction to this time capsule! Record a video to share your thoughts with the sender.',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRecordingReaction ? null : _recordReaction,
              icon: _isRecordingReaction
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.videocam),
              label: Text(
                _isRecordingReaction ? 'Uploading...' : 'Record Reaction Video',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordReaction() async {
    setState(() {
      _isRecordingReaction = true;
    });

    try {
      // Record video using StorageService (30s limit)
      final videoFile = await _storageService.recordVideoFromCamera();

      if (videoFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recording cancelled')));
        }
        return;
      }

      // Upload reaction video
      final reactionUrl = await _storageService.uploadReactionVideo(
        file: videoFile,
        capsuleId: widget.capsule.capsuleId,
      );

      // Update capsule in Firestore
      if (reactionUrl != null) {
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
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh to show reaction
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

    if (confirmed == true) {
      if (!mounted) return;
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
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        // Close detail screen
        // ignore: use_build_context_synchronously
        Navigator.pop(context);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capsule deleted successfully')),
        );
      }
    }
  }
}
