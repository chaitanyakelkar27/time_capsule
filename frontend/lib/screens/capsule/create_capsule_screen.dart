import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/capsule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
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
  File? _selectedImageFile;
  File? _selectedVideoFile;
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

    final users = await capsuleProvider.getUsers(authProvider.user!.userId);
    setState(() {
      _users = users;
      _isLoadingUsers = false;
    });
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
    if (file != null) {
      setState(() {
        _selectedImageFile = file;
        _capsuleType = 'image';
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final file = await _storageService.pickImageFromCamera();
    if (file != null) {
      setState(() {
        _selectedImageFile = file;
        _capsuleType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _storageService.pickVideoFromGallery();
    if (file != null) {
      setState(() {
        _selectedVideoFile = file;
        _capsuleType = 'video';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
        _locationAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location captured! 📍')),
        );
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

    setState(() => _isUploading = true);

    try {
      // Upload media if present
      if (_selectedImageFile != null) {
        _imageUrl = await _storageService.uploadCapsuleMedia(
          _selectedImageFile!,
          'image',
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );
      }

      if (_selectedVideoFile != null) {
        _videoUrl = await _storageService.uploadCapsuleMedia(
          _selectedVideoFile!,
          'video',
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );
      }

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
        message: _capsuleType == 'text' ? _messageController.text.trim() : null,
        imageUrl: _imageUrl,
        videoUrl: _videoUrl,
        unlockType: _unlockType,
        unlockDate: _unlockType == 'time' ? _getCombinedDateTime() : null,
        unlockLocation: _unlockType == 'location' ? _selectedLocation : null,
        unlockRadius: _unlockType == 'location' ? _unlockRadius : null,
        isLocationLocked: _unlockType == 'location',
        status: 'locked',
        isLocked: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await capsuleProvider.createCapsule(capsule);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capsule created successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    child: Image.file(
                                      _selectedImageFile!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedImageFile = null;
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
                                        _selectedVideoFile!.path.split('/').last,
                                        style: const TextStyle(color: Colors.white70),
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
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: _capsuleType == 'text' ? 'Message' : 'Caption (Optional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (_capsuleType == 'text' && (value == null || value.isEmpty)) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Recipient Selection
                    DropdownButtonFormField<String>(
                      value: _selectedRecipientId,
                      decoration: const InputDecoration(
                        labelText: 'Send To',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      hint: const Text('Select Recipient'),
                      items: _users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['userId'],
                          child: Text(user['displayName'] ?? user['email']),
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
                      value: _unlockType,
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
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_locationAddress ?? 'Location captured'),
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
                              onPressed: capsuleProvider.isLoading || _isUploading
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
                              label: Text(_isUploading ? 'Uploading...' : 'Create Capsule'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
  }
}
