import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/capsule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capsule_provider.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _capsuleType = 'text';
  String _unlockType = 'time';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRecipientId;
  String? _selectedRecipientName;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

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
      unlockType: _unlockType,
      unlockDate: _getCombinedDateTime(),
      unlockRadius: 100.0,
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

                    // Capsule Type
                    DropdownButtonFormField<String>(
                      value: _capsuleType,
                      decoration: const InputDecoration(
                        labelText: 'Capsule Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'text',
                          child: Text('Text Message'),
                        ),
                        DropdownMenuItem(
                          value: 'image',
                          child: Text('Image (Coming Soon)'),
                        ),
                        DropdownMenuItem(
                          value: 'video',
                          child: Text('Video (Coming Soon)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _capsuleType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Message (only for text type)
                    if (_capsuleType == 'text')
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                    if (_capsuleType == 'text') const SizedBox(height: 16),

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
                          child: Text('Location-Based (Coming Soon)'),
                        ),
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('Time + Location (Coming Soon)'),
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
                    if (_unlockType == 'time' || _unlockType == 'both') ...[
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

                    // Create Button
                    Consumer<CapsuleProvider>(
                      builder: (context, capsuleProvider, child) {
                        return ElevatedButton.icon(
                          onPressed: capsuleProvider.isLoading
                              ? null
                              : _createCapsule,
                          icon: capsuleProvider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock),
                          label: const Text('Create Capsule'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
