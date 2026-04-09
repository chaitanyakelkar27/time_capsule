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
              backgroundColor: Colors.orange,
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.green,
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
            content: Text('AI message generated! ✨'),
            backgroundColor: Colors.green,
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
            content: Text('Message enhanced! ✨'),
            backgroundColor: Colors.green,
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
      // Upload media if present
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
        capsuleId: '', // Will be set by Firestore
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
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Capsule sent to $_selectedRecipientName!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Log confirmation for debugging
        AppLogger.info('Capsule created successfully!');
        AppLogger.info('Sender: ${currentUser.userId}');
        AppLogger.info(
          'Recipient: $_selectedRecipientId ($_selectedRecipientName)',
        );

        // Navigate back to home screen
        if (!mounted) return;
        Navigator.of(context).pop();
      } else if (mounted && capsuleProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(capsuleProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Create Time Capsule')),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Capsule Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Media Buttons
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Media (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _pickImageFromCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _pickVideo,
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('Video'),
                                ),
                              ],
                            ),
                            if (_selectedImageFile != null) ...[
                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildSelectedImagePreview(),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedImageFile = null;
                                          _selectedImageBytes = null;
                                          _capsuleType = 'text';
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                      color: Colors.white,
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_selectedVideoFile != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Icon(
                                        Icons.video_file,
                                        size: 48,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _selectedVideoFile!.path
                                            .split('/')
                                            .last,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedVideoFile = null;
                                          _capsuleType = 'text';
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message (only for text type or as caption)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: _capsuleType == 'text'
                                ? 'Message'
                                : 'Caption (Optional)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.message),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isGeneratingAI
                                    ? null
                                    : _generateAIMessage,
                                icon: _isGeneratingAI
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: Text(
                                  _isGeneratingAI
                                      ? 'Generating...'
                                      : 'AI Suggest',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8B5CF6),
                                  side: const BorderSide(
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isGeneratingAI
                                    ? null
                                    : _enhanceMessage,
                                icon: _isGeneratingAI
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.stars, size: 18),
                                label: Text(
                                  _isGeneratingAI
                                      ? 'Enhancing...'
                                      : 'AI Enhance',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFC084FC),
                                  side: const BorderSide(
                                    color: Color(0xFFC084FC),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recipient Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRecipientId,
                      decoration: InputDecoration(
                        labelText: 'Send To',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        helperText: _users.isEmpty
                            ? 'No users available. Invite friends to join!'
                            : 'Select who will receive this capsule',
                      ),
                      hint: Text(
                        _users.isEmpty
                            ? 'No recipients available'
                            : 'Select Recipient',
                      ),
                      items: _users.isEmpty
                          ? null
                          : _users.map((user) {
                              return DropdownMenuItem<String>(
                                value: user['userId'],
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.deepPurple
                                          .withValues(alpha: 0.2),
                                      child: Text(
                                        (user['displayName'] ??
                                                user['email'])[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      user['displayName'] ?? 'No name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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
                    const SizedBox(height: 16),

                    // Unlock Type
                    DropdownButtonFormField<String>(
                      initialValue: _unlockType,
                      decoration: const InputDecoration(
                        labelText: 'Unlock Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_clock),
                      ),
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

                    // Date and Time Selection (for time-based)
                    if (_unlockType == 'time') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _selectedTime == null
                                    ? 'Select Time'
                                    : _selectedTime!.format(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location Selection (for location-based)
                    if (_unlockType == 'location') ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unlock Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Capture Current Location'),
                              ),
                              if (_selectedLocation != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _locationAddress ??
                                              'Location captured',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Unlock Radius',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Slider(
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
                                Text(
                                  'Recipient must be within ${_unlockRadius.toInt()} meters to unlock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Create Button
                    Consumer<CapsuleProvider>(
                      builder: (context, capsuleProvider, child) {
                        return Column(
                          children: [
                            if (_isUploading) ...[
                              LinearProgressIndicator(value: _uploadProgress),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 16),
                            ],
                            ElevatedButton.icon(
                              onPressed:
                                  capsuleProvider.isLoading || _isUploading
                                  ? null
                                  : _createCapsule,
                              icon: (capsuleProvider.isLoading || _isUploading)
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.lock),
                              label: Text(
                                _isUploading
                                    ? 'Uploading...'
                                    : 'Create Capsule',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
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
}
