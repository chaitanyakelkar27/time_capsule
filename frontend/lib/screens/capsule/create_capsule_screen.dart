import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/capsule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../services/ai_service.dart';
import '../../utils/app_logger.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _storageService = StorageService();
  final _locationService = LocationService();
  final _aiService = AIService();
  bool _isGeneratingAI = false;

  String _capsuleType = 'text';
  String _unlockType = 'time';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRecipientId;
  String? _selectedRecipientName;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Media
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  XFile? _selectedVideoFile;
  String? _imageUrl;
  String? _videoUrl;

  // Location
  GeoPoint? _selectedLocation;
  double _unlockRadius = 100.0;
  String? _locationAddress;

  // Step tracking
  final int _currentStep = 0; // 0=content, 1=recipient, 2=unlock

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final capsuleProvider = Provider.of<CapsuleProvider>(
      context,
      listen: false,
    );

    try {
      final users = await capsuleProvider.getUsers(authProvider.user!.userId);
      AppLogger.info('Loaded ${users.length} users for recipient selection');
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });

      if (users.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No other users found. Invite friends to join!'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error loading users', e);
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime? _getCombinedDateTime() {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _pickImageFromGallery() async {
    final file = await _storageService.pickImageFromGallery();
    if (!mounted) return;

    if (file != null) {
      final bytes = kIsWeb ? await file.readAsBytes() : null;
      setState(() {
        _selectedImageFile = file;
        _selectedImageBytes = bytes;
        _selectedVideoFile = null;
        _capsuleType = 'image';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No image selected. Please allow gallery access and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    final file = await _storageService.pickImageFromCamera();
    if (!mounted) return;

    if (file != null) {
      final bytes = kIsWeb ? await file.readAsBytes() : null;
      setState(() {
        _selectedImageFile = file;
        _selectedImageBytes = bytes;
        _selectedVideoFile = null;
        _capsuleType = 'image';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not capture image. Please allow camera access and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    final file = await _storageService.pickVideoFromGallery();
    if (!mounted) return;

    if (file != null) {
      setState(() {
        _selectedVideoFile = file;
        _selectedImageFile = null;
        _selectedImageBytes = null;
        _capsuleType = 'video';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No video selected. Please allow gallery access and try again.',
          ),
        ),
      );
    }
  }

  Widget _buildSelectedImagePreview() {
    if (_selectedImageFile == null) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      if (_selectedImageBytes != null) {
        return Image.memory(
          _selectedImageBytes!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }

      return Image.network(
        _selectedImageFile!.path,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(_selectedImageFile!.path),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
        _locationAddress =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _generateAIMessage() async {
    setState(() => _isGeneratingAI = true);

    try {
      final messageContext = _titleController.text.isNotEmpty
          ? _titleController.text
          : 'a meaningful time capsule message';

      final unlockInfo = _unlockType == 'time'
          ? (_selectedDate != null
                ? '${_selectedDate!.toString().split(' ')[0]}${_selectedTime != null ? ' at ${_selectedTime!.format(context)}' : ''}'
                : 'future time')
          : 'a special location';

      final suggestion = await _aiService.suggestMessage(
        context: messageContext,
        recipientName: _selectedRecipientName ?? 'someone special',
        unlockType: unlockInfo,
      );

      setState(() {
        _messageController.text = suggestion;
        _isGeneratingAI = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI message generated!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingAI = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI generation failed: $e')));
      }
    }
  }

  Future<void> _enhanceMessage() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a message first to enhance it')),
      );
      return;
    }

    setState(() => _isGeneratingAI = true);

    try {
      final enhanced = await _aiService.enhanceMessage(_messageController.text);
      setState(() {
        _messageController.text = enhanced;
        _isGeneratingAI = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message enhanced!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingAI = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enhancement failed: $e')));
      }
    }
  }

  Future<void> _createCapsule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRecipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient')),
      );
      return;
    }

    if (_unlockType == 'time' && _getCombinedDateTime() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select unlock date and time')),
      );
      return;
    }

    if (_unlockType == 'location' && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture unlock location')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      if (_selectedImageFile != null) {
        _imageUrl = await _storageService.uploadCapsuleMedia(
          file: _selectedImageFile!,
          capsuleId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          type: 'image',
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );

        if (_imageUrl == null) {
          throw Exception(
            'Image upload failed. Please check your internet connection and storage permissions, then try again.',
          );
        }
      }

      if (_selectedVideoFile != null) {
        _videoUrl = await _storageService.uploadCapsuleMedia(
          file: _selectedVideoFile!,
          capsuleId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          type: 'video',
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );

        if (_videoUrl == null) {
          throw Exception(
            'Video upload failed. Please check your internet connection and storage permissions, then try again.',
          );
        }
      }

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final capsuleProvider = Provider.of<CapsuleProvider>(
        context,
        listen: false,
      );
      final currentUser = authProvider.user!;

      final capsule = CapsuleModel(
        capsuleId: '',
        senderId: currentUser.userId,
        recipientId: _selectedRecipientId!,
        senderName: currentUser.displayName,
        recipientName: _selectedRecipientName!,
        type: _capsuleType,
        title: _titleController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        mediaUrl: _imageUrl ?? _videoUrl,
        unlockType: _unlockType,
        unlockDate: _unlockType == 'time' ? _getCombinedDateTime() : null,
        unlockLocation: _unlockType == 'location' ? _selectedLocation : null,
        unlockRadius: _unlockType == 'location' ? _unlockRadius : null,
        status: 'locked',
        isLocked: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await capsuleProvider.createCapsule(capsule);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Capsule sent to $_selectedRecipientName!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );

        AppLogger.info('Capsule created successfully!');
        AppLogger.info('Sender: ${currentUser.userId}');
        AppLogger.info(
          'Recipient: $_selectedRecipientId ($_selectedRecipientName)',
        );

        if (!mounted) return;
        Navigator.of(context).pop();
      } else if (mounted && capsuleProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(capsuleProvider.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Capsule', style: AppTheme.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Step Indicator ────────────────────
                    _buildStepIndicator(),
                    const SizedBox(height: 24),

                    // ── Title ─────────────────────────────
                    _buildSectionLabel('TITLE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Future Note to Self',
                        prefixIcon: Icon(Icons.title, color: AppTheme.textMuted, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Media ─────────────────────────────
                    _buildSectionLabel('MEDIA (OPTIONAL)'),
                    const SizedBox(height: 8),
                    _buildMediaSection(),
                    const SizedBox(height: 20),

                    // ── Message ───────────────────────────
                    _buildSectionLabel(_capsuleType == 'text' ? 'MESSAGE' : 'CAPTION (OPTIONAL)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Write your message to the future...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 80),
                          child: Icon(Icons.chat_bubble_outline, color: AppTheme.textMuted, size: 20),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (_capsuleType == 'text' &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildAIButtons(),
                    const SizedBox(height: 20),

                    // ── Recipient ─────────────────────────
                    _buildSectionLabel('RECIPIENT'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRecipientId,
                      decoration: const InputDecoration(
                        hintText: 'Select Recipient',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
                      ),
                      dropdownColor: AppTheme.cardBg,
                      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      items: _users.isEmpty
                          ? null
                          : _users.map((user) {
                              return DropdownMenuItem<String>(
                                value: user['userId'],
                                child: Text(
                                  user['displayName'] ?? 'No name',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                      onChanged: (value) {
                        final selectedUser = _users.firstWhere(
                          (u) => u['userId'] == value,
                        );
                        setState(() {
                          _selectedRecipientId = value;
                          _selectedRecipientName = selectedUser['displayName'];
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a recipient';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Unlock Type ──────────────────────
                    _buildSectionLabel('UNLOCK TYPE'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _unlockType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.schedule, color: AppTheme.textMuted, size: 20),
                      ),
                      dropdownColor: AppTheme.cardBg,
                      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                      items: const [
                        DropdownMenuItem(
                          value: 'time',
                          child: Text('Time-Based'),
                        ),
                        DropdownMenuItem(
                          value: 'location',
                          child: Text('Location-Based'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _unlockType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Time Selection ────────────────────
                    if (_unlockType == 'time') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                              label: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: AppTheme.body.copyWith(
                                  color: _selectedDate != null ? AppTheme.textPrimary : AppTheme.textMuted,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.inputBorder),
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                              label: Text(
                                _selectedTime == null
                                    ? 'Select Time'
                                    : _selectedTime!.format(context),
                                style: AppTheme.body.copyWith(
                                  color: _selectedTime != null ? AppTheme.textPrimary : AppTheme.textMuted,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.inputBorder),
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Location Selection ───────────────
                    if (_unlockType == 'location') ...[
                      _buildLocationSection(),
                      const SizedBox(height: 20),
                    ],

                    // ── Create Button ────────────────────
                    Consumer<CapsuleProvider>(
                      builder: (context, capsuleProvider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isUploading) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                child: LinearProgressIndicator(
                                  value: _uploadProgress,
                                  minHeight: 3,
                                  backgroundColor: AppTheme.divider,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                                style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                            FilledButton(
                              onPressed:
                                  capsuleProvider.isLoading || _isUploading
                                  ? null
                                  : _createCapsule,
                              child: (capsuleProvider.isLoading || _isUploading)
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create Capsule'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Helpers ────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(text, style: AppTheme.label);
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Step ${_currentStep + 1} of 3',
          style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 12),
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: i == _currentStep ? 8 : 6,
            height: i == _currentStep ? 8 : 6,
            decoration: BoxDecoration(
              color: i == _currentStep ? AppTheme.primary : AppTheme.inputBorder,
              shape: BoxShape.circle,
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _buildMediaSection() {
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMediaChip(Icons.photo_library_outlined, 'Gallery', _pickImageFromGallery),
              _buildMediaChip(Icons.camera_alt_outlined, 'Camera', _pickImageFromCamera),
              _buildMediaChip(Icons.videocam_outlined, 'Video', _pickVideo),
            ],
          ),
          if (_selectedImageFile != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  child: _buildSelectedImagePreview(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                        _capsuleType = 'text';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.scaffold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: AppTheme.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_selectedVideoFile != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.scaffold,
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, size: 24, color: AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedVideoFile!.path.split('/').last,
                      style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVideoFile = null;
                        _capsuleType = 'text';
                      });
                    },
                    child: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.scaffold,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppTheme.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.body.copyWith(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildAIChip(
            Icons.auto_awesome,
            _isGeneratingAI ? 'Generating...' : 'AI Suggest',
            _isGeneratingAI ? null : _generateAIMessage,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAIChip(
            Icons.auto_awesome,
            _isGeneratingAI ? 'Enhancing...' : 'AI Enhance',
            _isGeneratingAI ? null : _enhanceMessage,
          ),
        ),
      ],
    );
  }

  Widget _buildAIChip(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppTheme.inputBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
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
          Text('Unlock Location', style: AppTheme.subheading.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Capture Current Location'),
          ),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.scaffold,
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                border: Border.all(color: AppTheme.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationAddress ?? 'Location captured',
                      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Unlock Radius', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: AppTheme.divider,
                thumbColor: AppTheme.primary,
                overlayColor: AppTheme.primary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: _unlockRadius,
                min: 50,
                max: 1000,
                divisions: 19,
                label: '${_unlockRadius.toInt()}m',
                onChanged: (value) {
                  setState(() {
                    _unlockRadius = value;
                  });
                },
              ),
            ),
            Text(
              'Recipient must be within ${_unlockRadius.toInt()} meters to unlock',
              style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
