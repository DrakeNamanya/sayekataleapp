import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/admin_user.dart';
import '../../services/admin_service.dart';
import '../../services/csv_export_service.dart';
import 'complaint_detail_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  final AdminUser adminUser;

  const ComplaintsScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final AdminService _adminService = AdminService();
  final CsvExportService _csvExportService = CsvExportService();
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  Map<String, int>? _stats;
  bool _isLoading = true;
  bool _isExporting = false;
  
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  String _selectedPriority = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _loadStats();
    _searchController.addListener(_filterComplaints);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final complaints = await _adminService.getAllComplaints(limit: 200);
      setState(() {
        _complaints = complaints;
        _filteredComplaints = complaints;
        _isLoading = false;
      });
      _filterComplaints();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load complaints: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getComplaintsStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Silently fail for stats
    }
  }

  Future<void> _exportToCSV() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV export is only available on web platform'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await _csvExportService.exportComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Complaints exported to CSV successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _filterComplaints() {
    setState(() {
      _filteredComplaints = _complaints.where((complaint) {
        // Filter by status
        if (_selectedStatus != 'all' && complaint['status'] != _selectedStatus) {
          return false;
        }

        // Filter by category
        if (_selectedCategory != 'all' && complaint['category'] != _selectedCategory) {
          return false;
        }

        // Filter by priority
        if (_selectedPriority != 'all' && complaint['priority'] != _selectedPriority) {
          return false;
        }

        // Filter by search query
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final subject = (complaint['subject'] ?? '').toString().toLowerCase();
          final userName = (complaint['user_name'] ?? '').toString().toLowerCase();
          final description = (complaint['description'] ?? '').toString().toLowerCase();
          return subject.contains(query) || userName.contains(query) || description.contains(query);
        }

        return true;
      }).toList();

      // Sort by priority and date
      _filteredComplaints.sort((a, b) {
        // Priority order: urgent > high > medium > low
        final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
        final aPriority = priorityOrder[a['priority']] ?? 99;
        final bPriority = priorityOrder[b['priority']] ?? 99;
        
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        
        // If same priority, sort by date (newest first)
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });
    });
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'payment':
        return Icons.payment;
      case 'delivery':
        return Icons.local_shipping;
      case 'product':
        return Icons.inventory_2;
      case 'account':
        return Icons.person;
      case 'technical':
        return Icons.bug_report;
      default:
        return Icons.help_outline;
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
        title: const Text('Complaints Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (kIsWeb)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              onPressed: _isExporting ? null : _exportToCSV,
              tooltip: 'Export to CSV',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadComplaints();
              _loadStats();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary
          if (_stats != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatChip(
                          'Total',
                          _stats!['total'].toString(),
                          Colors.blue,
                          Icons.list_alt,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatChip(
                          'Pending',
                          _stats!['pending'].toString(),
                          Colors.orange,
                          Icons.pending,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatChip(
                          'In Progress',
                          _stats!['in_progress'].toString(),
                          Colors.blue,
                          Icons.sync,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatChip(
                          'Resolved',
                          _stats!['resolved'].toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.priority_high, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Urgent: ${_stats!['urgent']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'High: ${_stats!['high']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search complaints...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Status', _selectedStatus, [
                        {'value': 'all', 'label': 'All'},
                        {'value': 'pending', 'label': 'Pending'},
                        {'value': 'inProgress', 'label': 'In Progress'},
                        {'value': 'resolved', 'label': 'Resolved'},
                        {'value': 'closed', 'label': 'Closed'},
                      ], (value) {
                        setState(() => _selectedStatus = value);
                        _filterComplaints();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Category', _selectedCategory, [
                        {'value': 'all', 'label': 'All'},
                        {'value': 'payment', 'label': 'Payment'},
                        {'value': 'delivery', 'label': 'Delivery'},
                        {'value': 'product', 'label': 'Product'},
                        {'value': 'account', 'label': 'Account'},
                        {'value': 'technical', 'label': 'Technical'},
                      ], (value) {
                        setState(() => _selectedCategory = value);
                        _filterComplaints();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Priority', _selectedPriority, [
                        {'value': 'all', 'label': 'All'},
                        {'value': 'urgent', 'label': 'Urgent'},
                        {'value': 'high', 'label': 'High'},
                        {'value': 'medium', 'label': 'Medium'},
                        {'value': 'low', 'label': 'Low'},
                      ], (value) {
                        setState(() => _selectedPriority = value);
                        _filterComplaints();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Complaints List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredComplaints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.support_agent,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No complaints found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadComplaints();
                          await _loadStats();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _filteredComplaints[index];
                            return _buildComplaintCard(complaint);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<Map<String, String>> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${options.firstWhere((o) => o['value'] == currentValue)['label']}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(
                value: option['value'],
                child: Text(option['label']!),
              ))
          .toList(),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final priority = complaint['priority'] ?? 'low';
    final status = complaint['status'] ?? 'pending';
    final category = complaint['category'] ?? 'other';
    final priorityColor = _getPriorityColor(priority);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: priority == 'urgent'
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(
                complaintId: complaint['id'],
                adminUser: widget.adminUser,
              ),
            ),
          );
          
          if (result == true) {
            _loadComplaints();
            _loadStats();
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                      _getCategoryIcon(category),
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
                          complaint['user_name'] ?? 'Unknown user',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _getStatusDisplayName(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(complaint['created_at']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  if (complaint['assigned_to'] != null) ...[
                    Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (complaint['response'] != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.comment, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Responded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
