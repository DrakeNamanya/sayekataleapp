import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/admin_user.dart';
import '../../models/psa_verification.dart';
import '../../services/admin_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PsaVerificationScreen extends StatefulWidget {
  final AdminUser adminUser;

  const PsaVerificationScreen({super.key, required this.adminUser});

  @override
  State<PsaVerificationScreen> createState() => _PsaVerificationScreenState();
}

class _PsaVerificationScreenState extends State<PsaVerificationScreen> {
  final AdminService _adminService = AdminService();
  List<PsaVerification> _verifications = [];
  bool _isLoading = true;
  PsaVerificationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final verifications = await _adminService.getAllPsaVerifications(
        status: _filterStatus,
      );
      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load verifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PSA Verification'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<PsaVerificationStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
              _loadVerifications();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(
                value: PsaVerificationStatus.pending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: PsaVerificationStatus.underReview,
                child: Text('Under Review'),
              ),
              const PopupMenuItem(
                value: PsaVerificationStatus.approved,
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: PsaVerificationStatus.rejected,
                child: Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVerifications,
              child: _verifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No verification requests',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _verifications.length,
                      itemBuilder: (context, index) {
                        return _buildVerificationCard(_verifications[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildVerificationCard(PsaVerification verification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showVerificationDetails(verification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        verification.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      verification.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(verification.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeago.format(verification.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                verification.businessName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                verification.businessType,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, verification.contactPerson),
              _buildInfoRow(Icons.email, verification.email),
              _buildInfoRow(Icons.phone, verification.phoneNumber),
              _buildInfoRow(Icons.location_on, verification.businessAddress),
              const SizedBox(height: 12),
              // Document status
              Row(
                children: [
                  Icon(
                    verification.hasAllRequiredDocuments
                        ? Icons.check_circle
                        : Icons.warning,
                    size: 16,
                    color: verification.hasAllRequiredDocuments
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    verification.hasAllRequiredDocuments
                        ? 'All documents submitted'
                        : '${verification.missingDocuments.length} documents missing',
                    style: TextStyle(
                      fontSize: 12,
                      color: verification.hasAllRequiredDocuments
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (verification.status.canReview) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(verification),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: verification.hasAllRequiredDocuments
                            ? () => _showApproveDialog(verification)
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PsaVerificationStatus status) {
    switch (status) {
      case PsaVerificationStatus.pending:
        return Colors.orange;
      case PsaVerificationStatus.underReview:
        return Colors.blue;
      case PsaVerificationStatus.approved:
        return Colors.green;
      case PsaVerificationStatus.rejected:
        return Colors.red;
      case PsaVerificationStatus.moreInfoRequired:
        return Colors.amber;
    }
  }

  void _showVerificationDetails(PsaVerification verification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      verification.businessName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    verification.status,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verification.status.displayName,
                  style: TextStyle(
                    color: _getStatusColor(verification.status),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Business Information
              _buildSectionTitle('Business Information'),
              _buildDetailItem('Business Type', verification.businessType),
              _buildDetailItem('Contact Person', verification.contactPerson),
              _buildDetailItem('Email', verification.email),
              _buildDetailItem('Phone', verification.phoneNumber),
              _buildDetailItem('Address', verification.businessAddress),
              if (verification.businessDistrict != null)
                _buildDetailItem('District', verification.businessDistrict!),
              if (verification.businessVillage != null)
                _buildDetailItem('Village', verification.businessVillage!),
              const SizedBox(height: 24),

              // Tax Information
              _buildSectionTitle('Tax Information'),
              _buildDetailItem(
                'Tax ID (TIN)',
                verification.taxId ?? 'Not provided',
              ),
              const SizedBox(height: 24),

              // Bank Account Details
              _buildSectionTitle('Bank Account Details'),
              _buildDetailItem(
                'Account Holder',
                verification.bankAccountHolderName ?? 'Not provided',
              ),
              _buildDetailItem(
                'Account Number',
                verification.bankAccountNumber ?? 'Not provided',
              ),
              _buildDetailItem(
                'Bank Name',
                verification.bankName ?? 'Not provided',
              ),
              _buildDetailItem(
                'Branch',
                verification.bankBranch ?? 'Not provided',
              ),
              const SizedBox(height: 24),

              // Payment Methods
              _buildSectionTitle('Accepted Payment Methods'),
              if (verification.paymentMethods.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: verification.paymentMethods.map((method) {
                    return Chip(
                      label: Text(method),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                )
              else
                Text(
                  'No payment methods specified',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              const SizedBox(height: 24),

              // Documents
              _buildSectionTitle('Submitted Documents'),
              _buildDocumentSection(
                'Business License',
                verification.businessLicenseUrl,
              ),
              _buildDocumentSection(
                'Tax ID Document',
                verification.taxIdDocumentUrl,
              ),
              _buildDocumentSection('National ID', verification.nationalIdUrl),
              _buildDocumentSection(
                'Trade License',
                verification.tradeLicenseUrl,
              ),

              if (verification.additionalDocuments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Additional Documents'),
                ...verification.additionalDocuments.map(
                  (url) => _buildDocumentSection('Document', url),
                ),
              ],

              if (verification.reviewNotes != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Review Notes'),
                Text(verification.reviewNotes!),
              ],

              if (verification.rejectionReason != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Rejection Reason'),
                Text(
                  verification.rejectionReason!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(String title, String? url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          url != null ? Icons.check_circle : Icons.error,
          color: url != null ? Colors.green : Colors.red,
        ),
        title: Text(title),
        subtitle: Text(url != null ? 'Submitted' : 'Not submitted'),
        trailing: url != null
            ? IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _showDocumentPreview(title, url),
              )
            : null,
      ),
    );
  }

  void _showDocumentPreview(String title, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text('Failed to load document'),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveDialog(PsaVerification verification) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve PSA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approve ${verification.businessName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Review Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approvePsa(verification, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(PsaVerification verification) {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject PSA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${verification.businessName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _rejectPsa(
                verification,
                reasonController.text,
                notesController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePsa(PsaVerification verification, String? notes) async {
    try {
      await _adminService.approvePsaVerification(
        verification.id,
        widget.adminUser.id,
        reviewNotes: notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PSA approved successfully')),
        );
      }
      await _loadVerifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to approve PSA: $e')));
      }
    }
  }

  Future<void> _rejectPsa(
    PsaVerification verification,
    String reason,
    String? notes,
  ) async {
    try {
      await _adminService.rejectPsaVerification(
        verification.id,
        widget.adminUser.id,
        reason,
        reviewNotes: notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PSA rejected')));
      }
      await _loadVerifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reject PSA: $e')));
      }
    }
  }
}
