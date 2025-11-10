import 'package:flutter/material.dart';
import '../../models/admin_user.dart';
import '../../services/admin_service.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  final AdminUser adminUser;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    required this.adminUser,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _resolutionController = TextEditingController();
  
  Map<String, dynamic>? _complaint;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadComplaint();
  }

  @override
  void dispose() {
    _responseController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final complaint = await _adminService.getComplaint(widget.complaintId);
      setState(() {
        _complaint = complaint;
        _isLoading = false;
        
        // Pre-fill response if already exists
        if (complaint?['response'] != null) {
          _responseController.text = complaint!['response'];
        }
        
        // Pre-fill resolution if already exists
        if (complaint?['resolution'] != null) {
          _resolutionController.text = complaint!['resolution'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load complaint: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      setState(() => _isSaving = true);
      await _adminService.updateComplaintStatus(
        widget.complaintId,
        newStatus,
        widget.adminUser.id,
      );
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Status updated to ${_getStatusDisplayName(newStatus)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _assignToSelf() async {
    try {
      setState(() => _isSaving = true);
      await _adminService.assignComplaint(
        widget.complaintId,
        widget.adminUser.id,
        widget.adminUser.id,
      );
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Complaint assigned to you')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign complaint: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a response')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      await _adminService.addComplaintResponse(
        widget.complaintId,
        widget.adminUser.id,
        _responseController.text.trim(),
      );
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Response added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add response: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _closeComplaint() async {
    if (_resolutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resolution summary')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Complaint'),
        content: const Text('Are you sure you want to close this complaint? This action marks it as resolved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Complaint'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isSaving = true);
      await _adminService.closeComplaint(
        widget.complaintId,
        widget.adminUser.id,
        _resolutionController.text.trim(),
      );
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Complaint closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to list with refresh flag
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close complaint: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _complaint != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'pending':
                  case 'inProgress':
                  case 'resolved':
                    _updateStatus(value);
                    break;
                  case 'assign':
                    _assignToSelf();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (_complaint!['status'] != 'inProgress')
                  const PopupMenuItem(
                    value: 'inProgress',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 20),
                        SizedBox(width: 8),
                        Text('Mark In Progress'),
                      ],
                    ),
                  ),
                if (_complaint!['status'] != 'resolved')
                  const PopupMenuItem(
                    value: 'resolved',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Mark Resolved'),
                      ],
                    ),
                  ),
                if (_complaint!['assigned_to'] == null)
                  const PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.person_add, size: 20),
                        SizedBox(width: 8),
                        Text('Assign to Me'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaint == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Complaint not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Priority Header
                      _buildHeaderCard(),
                      const SizedBox(height: 16),

                      // Complaint Details
                      _buildDetailsCard(),
                      const SizedBox(height: 16),

                      // User Information
                      _buildUserInfoCard(),
                      const SizedBox(height: 16),

                      // Response Section
                      if (widget.adminUser.hasPermission(AdminPermissions.handleComplaints))
                        _buildResponseSection(),
                      const SizedBox(height: 16),

                      // Close Complaint Section
                      if (_complaint!['status'] != 'closed' &&
                          widget.adminUser.hasPermission(AdminPermissions.handleComplaints))
                        _buildCloseComplaintSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final priority = _complaint!['priority'] ?? 'low';
    final status = _complaint!['status'] ?? 'pending';
    final priorityColor = _getPriorityColor(priority);
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${priority.toUpperCase()} PRIORITY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Text(
                _getStatusDisplayName(status).toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaint Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('Subject', _complaint!['subject'] ?? 'N/A'),
            _buildDetailRow('Category', _complaint!['category']?.toString().toUpperCase() ?? 'N/A'),
            _buildDetailRow('Description', _complaint!['description'] ?? 'N/A', isMultiline: true),
            // Display attachments if any
            if (_complaint!['attachments'] != null && (_complaint!['attachments'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Attachments:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: (_complaint!['attachments'] as List).map<Widget>((attachmentUrl) {
                  return GestureDetector(
                    onTap: () {
                      // Show fullscreen image
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text('Attachment'),
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.network(
                                  attachmentUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error, size: 48),
                                    );
                                  },
                                ),
                              ),
                            ),
                            backgroundColor: Colors.black,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.network(
                              attachmentUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, size: 40),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            _buildDetailRow('Created At', _formatDateTime(_complaint!['created_at'])),
            if (_complaint!['assigned_to'] != null)
              _buildDetailRow('Assigned To', _complaint!['assigned_to'], valueColor: Colors.blue),
            if (_complaint!['assigned_at'] != null)
              _buildDetailRow('Assigned At', _formatDateTime(_complaint!['assigned_at'])),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('User Name', _complaint!['user_name'] ?? 'N/A'),
            _buildDetailRow('User ID', _complaint!['user_id'] ?? 'N/A'),
            if (_complaint!['user_email'] != null)
              _buildDetailRow('Email', _complaint!['user_email']),
            if (_complaint!['user_phone'] != null)
              _buildDetailRow('Phone', _complaint!['user_phone']),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    final hasResponse = _complaint!['response'] != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Admin Response',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasResponse) ...[
                  const Spacer(),
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Responded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const Divider(),
            TextField(
              controller: _responseController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter your response to the user...',
                border: OutlineInputBorder(),
              ),
              enabled: _complaint!['status'] != 'closed',
            ),
            if (hasResponse) ...[
              const SizedBox(height: 8),
              Text(
                'Responded by: ${_complaint!['responded_by'] ?? 'Unknown'} at ${_formatDateTime(_complaint!['responded_at'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_complaint!['status'] != 'closed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _addResponse,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(hasResponse ? 'Update Response' : 'Send Response'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCloseComplaintSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Close Complaint',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const Text(
              'Enter resolution summary before closing:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resolutionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe how the complaint was resolved...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _closeComplaint,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close),
                label: const Text('Close Complaint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isMultiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: valueColor ?? Colors.black87),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '$label:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(color: valueColor ?? Colors.black87),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDateTime(dynamic dateValue) {
    try {
      if (dateValue == null) return 'N/A';
      final date = dateValue is DateTime
          ? dateValue
          : DateTime.parse(dateValue.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
