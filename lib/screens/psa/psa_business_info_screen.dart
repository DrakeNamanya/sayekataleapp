import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/psa_verification.dart';
import '../../services/psa_verification_service.dart';
import '../../utils/app_theme.dart';

/// Business Information Screen
/// Displays approved verification data in a read-only summary format
class PSABusinessInfoScreen extends StatefulWidget {
  const PSABusinessInfoScreen({super.key});

  @override
  State<PSABusinessInfoScreen> createState() => _PSABusinessInfoScreenState();
}

class _PSABusinessInfoScreenState extends State<PSABusinessInfoScreen> {
  final PSAVerificationService _verificationService = PSAVerificationService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Information'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<PsaVerification?>(
        stream: _verificationService.streamPsaVerification(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final verification = snapshot.data;

          if (verification == null) {
            return _buildNoVerificationView();
          }

          if (verification.status != PsaVerificationStatus.approved) {
            return _buildPendingVerificationView(verification.status);
          }

          // Show approved verification data
          return _buildApprovedBusinessInfo(verification);
        },
      ),
    );
  }

  Widget _buildNoVerificationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'No Business Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your business verification to see your business information here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingVerificationView(PsaVerificationStatus status) {
    String message = 'Your business verification is ';
    IconData icon = Icons.hourglass_empty;
    Color color = Colors.orange;

    switch (status) {
      case PsaVerificationStatus.pending:
        message += 'pending review';
        break;
      case PsaVerificationStatus.underReview:
        message += 'under review';
        color = Colors.blue;
        break;
      case PsaVerificationStatus.rejected:
        message = 'Your business verification was rejected. Please resubmit.';
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case PsaVerificationStatus.moreInfoRequired:
        message = 'More information required for verification';
        icon = Icons.info;
        color = Colors.amber;
        break;
      default:
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Business information will be available after approval',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedBusinessInfo(PsaVerification verification) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Business',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Your business has been verified and approved',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Profile
          _buildSection('Business Profile', [
            _buildInfoTile('Business Name', verification.businessName),
            _buildInfoTile('Business Type', verification.businessType),
            _buildInfoTile('Contact Person', verification.contactPerson),
            _buildInfoTile('Email', verification.email),
            _buildInfoTile('Phone Number', verification.phoneNumber),
            _buildInfoTile('Business Address', verification.businessAddress),
          ]),

          // Location Information
          if (verification.businessDistrict != null) ...[
            const SizedBox(height: 24),
            _buildSection('Location Information', [
              _buildInfoTile('District', verification.businessDistrict ?? 'N/A'),
              if (verification.businessSubcounty != null)
                _buildInfoTile('Subcounty', verification.businessSubcounty!),
              if (verification.businessParish != null)
                _buildInfoTile('Parish', verification.businessParish!),
              if (verification.businessVillage != null)
                _buildInfoTile('Village', verification.businessVillage!),
              if (verification.businessLatitude != null &&
                  verification.businessLongitude != null)
                _buildInfoTile(
                  'GPS Coordinates',
                  '${verification.businessLatitude!.toStringAsFixed(6)}, ${verification.businessLongitude!.toStringAsFixed(6)}',
                ),
            ]),
          ],

          // Tax Information
          if (verification.taxId != null) ...[
            const SizedBox(height: 24),
            _buildSection('Tax Information', [
              _buildInfoTile('Tax ID (TIN)', verification.taxId ?? 'Not provided'),
            ]),
          ],

          // Bank Account Details
          if (verification.bankAccountNumber != null) ...[
            const SizedBox(height: 24),
            _buildSection('Bank Account Details', [
              _buildInfoTile(
                'Account Holder',
                verification.bankAccountHolderName ?? 'Not provided',
              ),
              _buildInfoTile(
                'Account Number',
                verification.bankAccountNumber ?? 'Not provided',
              ),
              _buildInfoTile('Bank Name', verification.bankName ?? 'Not provided'),
              _buildInfoTile('Branch', verification.bankBranch ?? 'Not provided'),
            ]),
          ],

          // Payment Methods
          if (verification.paymentMethods.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection('Accepted Payment Methods', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: verification.paymentMethods.map((method) {
                  return Chip(
                    label: Text(method),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ]),
          ],

          // Verification Documents
          const SizedBox(height: 24),
          _buildSection('Verification Documents', [
            _buildDocumentTile('Business License', verification.businessLicenseUrl),
            _buildDocumentTile('Tax ID Document', verification.taxIdDocumentUrl),
            _buildDocumentTile('National ID', verification.nationalIdUrl),
            _buildDocumentTile('Trade License', verification.tradeLicenseUrl),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String title, String? url) {
    final hasDocument = url != null && url.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDocument ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDocument ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDocument ? Icons.check_circle : Icons.cancel,
            color: hasDocument ? Colors.green.shade700 : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  hasDocument ? 'Document verified' : 'Not submitted',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasDocument ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (hasDocument)
            IconButton(
              icon: const Icon(Icons.visibility),
              color: AppTheme.primaryColor,
              onPressed: () => _showDocumentPreview(title, url),
              tooltip: 'View document',
            ),
        ],
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
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Failed to load document'),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
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
}
