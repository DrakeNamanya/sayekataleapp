import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../utils/app_theme.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _recipientType = 'all'; // 'all', 'role', 'single'
  String? _selectedRole;
  String? _selectedUserId;
  NotificationType _notificationType = NotificationType.message;

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Type Selection
              _buildSectionTitle('Select Recipients'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('All Users'),
                      subtitle: const Text('Send to everyone in the app'),
                      value: 'all',
                      groupValue: _recipientType,
                      onChanged: (value) {
                        setState(() {
                          _recipientType = value!;
                          _selectedRole = null;
                          _selectedUserId = null;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('By User Role'),
                      subtitle: const Text('Send to specific user type'),
                      value: 'role',
                      groupValue: _recipientType,
                      onChanged: (value) {
                        setState(() {
                          _recipientType = value!;
                          _selectedUserId = null;
                        });
                      },
                    ),
                    if (_recipientType == 'role') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Role',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedRole,
                          items: const [
                            DropdownMenuItem(value: 'SHG', child: Text('SHG (Farmers)')),
                            DropdownMenuItem(value: 'SME', child: Text('SME (Buyers)')),
                            DropdownMenuItem(value: 'PSA', child: Text('PSA (Suppliers)')),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                          validator: (value) {
                            if (_recipientType == 'role' && value == null) {
                              return 'Please select a role';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Single User'),
                      subtitle: const Text('Send to a specific user'),
                      value: 'single',
                      groupValue: _recipientType,
                      onChanged: (value) {
                        setState(() {
                          _recipientType = value!;
                          _selectedRole = null;
                        });
                      },
                    ),
                    if (_recipientType == 'single') ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildUserSelector(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notification Type
              _buildSectionTitle('Notification Type'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<NotificationType>(
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _notificationType,
                        items: const [
                          DropdownMenuItem(
                            value: NotificationType.message,
                            child: Row(
                              children: [
                                Icon(Icons.message, size: 20),
                                SizedBox(width: 8),
                                Text('Message'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationType.promotion,
                            child: Row(
                              children: [
                                Icon(Icons.campaign, size: 20),
                                SizedBox(width: 8),
                                Text('Promotion'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationType.general,
                            child: Row(
                              children: [
                                Icon(Icons.info, size: 20),
                                SizedBox(width: 8),
                                Text('General'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationType.alert,
                            child: Row(
                              children: [
                                Icon(Icons.warning, size: 20),
                                SizedBox(width: 8),
                                Text('Alert'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _notificationType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notification Content
              _buildSectionTitle('Notification Content'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter notification title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                          hintText: 'Enter notification message',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNotification,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Select User',
            border: OutlineInputBorder(),
          ),
          value: _selectedUserId,
          items: users.map((user) {
            final userData = user.data() as Map<String, dynamic>;
            final name = userData['name'] ?? 'Unknown';
            final role = userData['role'] ?? 'Unknown';
            return DropdownMenuItem(
              value: user.id,
              child: Text('$name ($role)'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUserId = value;
            });
          },
          validator: (value) {
            if (_recipientType == 'single' && value == null) {
              return 'Please select a user';
            }
            return null;
          },
        );
      },
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Text(_getConfirmationMessage()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSending = true;
    });

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      switch (_recipientType) {
        case 'all':
          await _notificationService.sendNotificationToAllUsers(
            title: title,
            message: message,
            notificationType: _notificationType,
          );
          break;

        case 'role':
          await _notificationService.sendNotificationByRole(
            role: _selectedRole!,
            title: title,
            message: message,
            notificationType: _notificationType,
          );
          break;

        case 'single':
          await _notificationService.sendNotificationToUser(
            userId: _selectedUserId!,
            title: title,
            message: message,
            notificationType: _notificationType,
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Enhanced error logging
        if (kDebugMode) {
          debugPrint('🚨 ERROR sending notification: $e');
          debugPrint('   Error type: ${e.runtimeType}');
          debugPrint('   Full error: ${e.toString()}');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _getConfirmationMessage() {
    String recipients = '';
    switch (_recipientType) {
      case 'all':
        recipients = 'all users';
        break;
      case 'role':
        recipients = 'all $_selectedRole users';
        break;
      case 'single':
        recipients = 'the selected user';
        break;
    }

    return 'Are you sure you want to send this notification to $recipients?';
  }
}
