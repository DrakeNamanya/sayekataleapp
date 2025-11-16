import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_complaint.dart';
import '../../providers/auth_provider.dart';
import '../../services/complaint_service.dart';
import '../../services/image_storage_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  final ComplaintService _complaintService = ComplaintService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final TabController _tabController;

  ComplaintCategory _selectedCategory = ComplaintCategory.other;
  ComplaintPriority _selectedPriority = ComplaintPriority.medium;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _myComplaints = [];
  bool _isLoadingComplaints = true;

  // Image attachment state
  final ImagePicker _imagePicker = ImagePicker();
  final ImageStorageService _imageStorage = ImageStorageService();
  final List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserComplaints() async {
    if (kDebugMode) {
      debugPrint('\n🔄 HELP SUPPORT SCREEN - _loadUserComplaints started');
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final userId = currentUser?.id;

    if (kDebugMode) {
      debugPrint('👤 HELP SUPPORT SCREEN - Current User Info:');
      debugPrint(
        '   - User object: ${currentUser != null ? "EXISTS" : "NULL"}',
      );
      debugPrint('   - User ID: ${userId ?? "NULL"}');
      if (userId != null) {
        debugPrint('   - User ID type: ${userId.runtimeType}');
        debugPrint('   - User ID length: ${userId.length}');
        debugPrint('   - User name: ${currentUser?.name}');
        debugPrint('   - User email: ${currentUser?.email}');
      }
    }

    if (userId == null) {
      if (kDebugMode) {
        debugPrint('❌ HELP SUPPORT SCREEN - No user ID found, stopping load');
      }
      setState(() {
        _isLoadingComplaints = false;
      });
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '📞 HELP SUPPORT SCREEN - Calling ComplaintService.getUserComplaints...',
        );
      }

      final complaints = await _complaintService.getUserComplaints(userId);

      if (kDebugMode) {
        debugPrint(
          '✅ HELP SUPPORT SCREEN - Received ${complaints.length} complaints',
        );
        if (complaints.isNotEmpty) {
          debugPrint('📋 HELP SUPPORT SCREEN - Complaint details:');
          for (var i = 0; i < complaints.length && i < 3; i++) {
            final c = complaints[i];
            debugPrint('   Complaint $i:');
            debugPrint('     - ID: ${c['id']}');
            debugPrint('     - Subject: ${c['subject']}');
            debugPrint('     - Status: ${c['status']}');
            debugPrint('     - Has Response: ${c['response'] != null}');
          }
        }
      }

      setState(() {
        _myComplaints = complaints;
        _isLoadingComplaints = false;
      });

      if (kDebugMode) {
        debugPrint('✅ HELP SUPPORT SCREEN - State updated, UI should refresh');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ HELP SUPPORT SCREEN - ERROR loading complaints:');
        debugPrint('   - Error: $e');
        debugPrint('   - Stack trace: $stackTrace');
      }

      setState(() {
        _isLoadingComplaints = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load complaints: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && _selectedImages.length < 3) {
        setState(() {
          _selectedImages.add(image);
        });

        if (kDebugMode) {
          debugPrint('✅ Image added: ${image.name}');
        }
      } else if (_selectedImages.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 3 images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error picking image: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (kDebugMode) {
      debugPrint('\n📝 HELP SUPPORT SCREEN - _submitComplaint called');
      debugPrint('   - User object: ${user != null ? "EXISTS" : "NULL"}');
      if (user != null) {
        debugPrint('   - User ID: "${user.id}"');
        debugPrint('   - User ID type: ${user.id.runtimeType}');
        debugPrint('   - User name: ${user.name}');
      }
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a complaint')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isUploadingImages = true;
    });

    try {
      // Upload images first if any selected
      List<String> attachmentUrls = [];
      if (_selectedImages.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('📤 Uploading ${_selectedImages.length} images...');
        }

        for (int i = 0; i < _selectedImages.length; i++) {
          final imageFile = _selectedImages[i];
          try {
            final url = await _imageStorage.uploadImageFromXFile(
              imageFile: imageFile,
              folder: 'complaints',
              userId: user.id,
              customName:
                  'complaint_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              compress: true,
            );
            attachmentUrls.add(url);

            if (kDebugMode) {
              debugPrint('✅ Image ${i + 1}/${_selectedImages.length} uploaded');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Failed to upload image ${i + 1}: $e');
            }
          }
        }
      }

      setState(() {
        _isUploadingImages = false;
      });

      final complaintId = await _complaintService.submitComplaint(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        attachmentUrls: attachmentUrls,
      );

      if (kDebugMode) {
        debugPrint('✅ HELP SUPPORT SCREEN - Complaint submitted: $complaintId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Complaint submitted successfully! Our team will review it soon.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = ComplaintCategory.other;
          _selectedPriority = ComplaintPriority.medium;
          _selectedImages.clear();
        });

        // Reload complaints
        _loadUserComplaints();

        // Navigate back to complaints tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit complaint: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Submit Complaint', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'My Complaints', icon: Icon(Icons.list_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSubmitComplaintTab(), _buildMyComplaintsTab()],
      ),
    );
  }

  Widget _buildSubmitComplaintTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2E7D32),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Our support team will review your complaint and respond within 24-48 hours.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            const Text(
              'Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Priority Selection
            const Text(
              'Priority',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPrioritySelector(),
            const SizedBox(height: 24),

            // Subject
            const Text(
              'Subject',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Brief description of your issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                if (value.trim().length < 5) {
                  return 'Subject must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Provide detailed information about your issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Attachment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      const Text(
                        'Attachments (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _selectedImages.length < 3
                            ? _pickImage
                            : null,
                        icon: const Icon(Icons.add_photo_alternate, size: 20),
                        label: const Text('Add Image'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add screenshots or photos to help us understand your issue better (Max 3 images)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, size: 40),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upload Progress Indicator
            if (_isUploadingImages)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Uploading images...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit Complaint',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComplaintCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return FilterChip(
          label: Text(_getCategoryDisplayName(category)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = category;
            });
          },
          selectedColor: const Color(0xFF2E7D32),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          avatar: Icon(
            _getCategoryIcon(category),
            size: 18,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: ComplaintPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        final color = _getPriorityColor(priority);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Center(child: Text(_getPriorityDisplayName(priority))),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyComplaintsTab() {
    if (_isLoadingComplaints) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myComplaints.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUserComplaints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No complaints yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your submitted complaints will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (kDebugMode) {
                        debugPrint(
                          '\n🔄 MANUAL REFRESH - User tapped refresh button',
                        );
                      }
                      setState(() {
                        _isLoadingComplaints = true;
                      });
                      _loadUserComplaints();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myComplaints.length,
        itemBuilder: (context, index) {
          final complaint = _myComplaints[index];
          return _buildComplaintCard(complaint);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status'] ?? 'pending';
    final priority = complaint['priority'] ?? 'medium';
    final category = complaint['category'] ?? 'other';
    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(
      ComplaintPriority.values.firstWhere(
        (p) => p.toString().split('.').last == priority,
        orElse: () => ComplaintPriority.medium,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(
                      ComplaintCategory.values.firstWhere(
                        (c) => c.toString().split('.').last == category,
                        orElse: () => ComplaintCategory.other,
                      ),
                    ),
                    color: priorityColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint['subject'] ?? 'No subject',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTimeAgo(complaint['created_at']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getStatusDisplayName(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint['description'] ?? 'No description',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (complaint['response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Admin Response:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint['response'],
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(ComplaintCategory category) {
    return category.displayName;
  }

  IconData _getCategoryIcon(ComplaintCategory category) {
    switch (category) {
      case ComplaintCategory.payment:
        return Icons.payment;
      case ComplaintCategory.delivery:
        return Icons.local_shipping;
      case ComplaintCategory.product:
        return Icons.inventory_2;
      case ComplaintCategory.account:
        return Icons.person;
      case ComplaintCategory.technical:
        return Icons.bug_report;
      case ComplaintCategory.other:
        return Icons.help_outline;
    }
  }

  String _getPriorityDisplayName(ComplaintPriority priority) {
    return priority.displayName;
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.urgent:
        return Colors.red;
      case ComplaintPriority.high:
        return Colors.orange;
      case ComplaintPriority.medium:
        return Colors.blue;
      case ComplaintPriority.low:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'inProgress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'inProgress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';
      final dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
