import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../models/psa_verification.dart';
import '../../services/psa_verification_service.dart';
import '../../services/image_storage_service.dart';
import '../../utils/app_theme.dart';
import '../../data/location_data.dart';
/// Comprehensive PSA Profile Verification Form
/// All fields are mandatory for business verification
class PSAVerificationFormScreen extends StatefulWidget {
  final PsaVerification? existingVerification; // For editing existing submission

  const PSAVerificationFormScreen({
    super.key,
    this.existingVerification,
  });

  @override
  State<PSAVerificationFormScreen> createState() =>
      _PSAVerificationFormScreenState();
}

class _PSAVerificationFormScreenState extends State<PSAVerificationFormScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Business Profile
  final _businessNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedBusinessType = 'Input Supplier';

  // Step 2: Business Location (with cascading hierarchy)
  final _businessAddressController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedSubcounty;
  String? _selectedParish;
  String? _selectedVillage;
  double? _businessLatitude;
  double? _businessLongitude;
  bool _isCapturingGPS = false;

  // Step 3: Tax Information
  final _taxIdController = TextEditingController();

  // Step 4: Bank Account Details
  final _bankAccountHolderController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  String _selectedBank = 'Stanbic Bank';
  final _bankBranchController = TextEditingController();

  // Step 5: Payment Methods
  final List<String> _availablePaymentMethods = [
    'Mobile Money',
    'Bank Transfer',
    'Cash on Delivery'
  ];
  final List<String> _selectedPaymentMethods = [];

  // Step 6: Verification Documents (using XFile for web compatibility)
  XFile? _businessLicenseFile;
  XFile? _taxIdDocumentFile;
  XFile? _nationalIdFile;
  XFile? _tradeLicenseFile;
  String? _businessLicenseUrl;
  String? _taxIdDocumentUrl;
  String? _nationalIdUrl;
  String? _tradeLicenseUrl;

  // Location data from Excel file (12 Eastern Uganda districts)
  final List<String> _districts = LocationData.districts;

  final List<String> _businessTypes = [
    'Input Supplier',
    'Equipment Rental',
    'Transport Services',
    'Warehouse/Storage',
    'Agricultural Processing',
    'Veterinary Services',
    'Other'
  ];

  final List<String> _banks = [
    'Stanbic Bank',
    'Bank of Africa',
    'Centenary Bank',
    'DFCU Bank',
    'Equity Bank',
    'Standard Chartered',
    'Absa Bank',
    'Housing Finance Bank',
    'Pride Microfinance',
    'Other'
  ];

  final _imagePicker = ImagePicker();
  final _psaVerificationService = PSAVerificationService();
  final _imageStorageService = ImageStorageService();

  @override
  void initState() {
    super.initState();
    if (widget.existingVerification != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final verification = widget.existingVerification!;
    _businessNameController.text = verification.businessName;
    _contactPersonController.text = verification.contactPerson;
    _emailController.text = verification.email;
    _phoneController.text = verification.phoneNumber;
    _businessAddressController.text = verification.businessAddress;
    _selectedBusinessType = verification.businessType;
    
    if (verification.businessDistrict != null) {
      _selectedDistrict = verification.businessDistrict!;
    }
    if (verification.businessSubcounty != null) {
      _selectedSubcounty = verification.businessSubcounty!;
    }
    if (verification.businessParish != null) {
      _selectedParish = verification.businessParish!;
    }
    if (verification.businessVillage != null) {
      _selectedVillage = verification.businessVillage!;
    }
    if (verification.businessLatitude != null) {
      _businessLatitude = verification.businessLatitude!;
    }
    if (verification.businessLongitude != null) {
      _businessLongitude = verification.businessLongitude!;
    }
    if (verification.taxId != null) {
      _taxIdController.text = verification.taxId!;
    }
    if (verification.bankAccountHolderName != null) {
      _bankAccountHolderController.text = verification.bankAccountHolderName!;
    }
    if (verification.bankAccountNumber != null) {
      _bankAccountNumberController.text = verification.bankAccountNumber!;
    }
    if (verification.bankName != null) {
      _selectedBank = verification.bankName!;
    }
    if (verification.bankBranch != null) {
      _bankBranchController.text = verification.bankBranch!;
    }
    
    _selectedPaymentMethods.addAll(verification.paymentMethods);
    _businessLicenseUrl = verification.businessLicenseUrl;
    _taxIdDocumentUrl = verification.taxIdDocumentUrl;
    _nationalIdUrl = verification.nationalIdUrl;
    _tradeLicenseUrl = verification.tradeLicenseUrl;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessAddressController.dispose();
    _taxIdController.dispose();
    _bankAccountHolderController.dispose();
    _bankAccountNumberController.dispose();
    _bankBranchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String documentType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'business_license':
              _businessLicenseFile = image;
              break;
            case 'tax_id':
              _taxIdDocumentFile = image;
              break;
            case 'national_id':
              _nationalIdFile = image;
              break;
            case 'trade_license':
              _tradeLicenseFile = image;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _nextStep() async {
    // Validate current step before moving to next
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitVerification();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Business Profile
        return _businessNameController.text.isNotEmpty &&
            _contactPersonController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      case 1: // Business Location
        return _businessAddressController.text.isNotEmpty &&
            _selectedDistrict != null &&
            _selectedSubcounty != null &&
            _selectedParish != null &&
            _selectedVillage != null;
      case 2: // Tax Information
        return _taxIdController.text.isNotEmpty;
      case 3: // Bank Account
        return _bankAccountHolderController.text.isNotEmpty &&
            _bankAccountNumberController.text.isNotEmpty &&
            _bankBranchController.text.isNotEmpty;
      case 4: // Payment Methods
        return _selectedPaymentMethods.isNotEmpty;
      case 5: // Documents
        return (_businessLicenseFile != null || _businessLicenseUrl != null) &&
            (_taxIdDocumentFile != null || _taxIdDocumentUrl != null) &&
            (_nationalIdFile != null || _nationalIdUrl != null) &&
            (_tradeLicenseFile != null || _tradeLicenseUrl != null);
      default:
        return false;
    }
  }

  Future<void> _submitVerification() async {
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final psaId = authProvider.currentUser?.id;

      if (psaId == null) {
        throw Exception('User not authenticated');
      }

      // Upload new documents to Firebase Storage
      if (_businessLicenseFile != null && _businessLicenseUrl == null) {
        _businessLicenseUrl = await _imageStorageService.uploadImageFromXFile(
          imageFile: _businessLicenseFile!,
          folder: 'psa_verifications',
          userId: psaId,
          customName: 'business_license_${DateTime.now().millisecondsSinceEpoch}',
          compress: false, // Don't compress documents
        );
      }

      if (_taxIdDocumentFile != null && _taxIdDocumentUrl == null) {
        _taxIdDocumentUrl = await _imageStorageService.uploadImageFromXFile(
          imageFile: _taxIdDocumentFile!,
          folder: 'psa_verifications',
          userId: psaId,
          customName: 'tax_id_document_${DateTime.now().millisecondsSinceEpoch}',
          compress: false, // Don't compress documents
        );
      }

      if (_nationalIdFile != null && _nationalIdUrl == null) {
        _nationalIdUrl = await _imageStorageService.uploadImageFromXFile(
          imageFile: _nationalIdFile!,
          folder: 'psa_verifications',
          userId: psaId,
          customName: 'national_id_${DateTime.now().millisecondsSinceEpoch}',
          compress: false, // Don't compress documents
        );
      }

      if (_tradeLicenseFile != null && _tradeLicenseUrl == null) {
        _tradeLicenseUrl = await _imageStorageService.uploadImageFromXFile(
          imageFile: _tradeLicenseFile!,
          folder: 'psa_verifications',
          userId: psaId,
          customName: 'trade_license_${DateTime.now().millisecondsSinceEpoch}',
          compress: false, // Don't compress documents
        );
      }

      // Debug: Log document URLs before creating verification
      if (kDebugMode) {
        debugPrint('📄 Document URLs before creating verification:');
        debugPrint('   Business License: ${_businessLicenseUrl ?? "NULL"}');
        debugPrint('   Tax ID Document: ${_taxIdDocumentUrl ?? "NULL"}');
        debugPrint('   National ID: ${_nationalIdUrl ?? "NULL"}');
        debugPrint('   Trade License: ${_tradeLicenseUrl ?? "NULL"}');
      }

      // Create verification request
      final verification = PsaVerification(
        id: widget.existingVerification?.id ?? '',
        psaId: psaId,
        businessName: _businessNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessType: _selectedBusinessType,
        businessDistrict: _selectedDistrict,
        businessSubcounty: _selectedSubcounty,
        businessParish: _selectedParish,
        businessVillage: _selectedVillage,
        businessLatitude: _businessLatitude,
        businessLongitude: _businessLongitude,
        taxId: _taxIdController.text.trim(),
        bankAccountHolderName: _bankAccountHolderController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        bankName: _selectedBank,
        bankBranch: _bankBranchController.text.trim(),
        paymentMethods: _selectedPaymentMethods,
        businessLicenseUrl: _businessLicenseUrl,
        taxIdDocumentUrl: _taxIdDocumentUrl,
        nationalIdUrl: _nationalIdUrl,
        tradeLicenseUrl: _tradeLicenseUrl,
        status: PsaVerificationStatus.pending,
        createdAt: widget.existingVerification?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (kDebugMode) {
        debugPrint('✅ Verification object created with status: ${verification.status}');
        debugPrint('   Has all documents: ${verification.hasAllRequiredDocuments}');
      }

      if (widget.existingVerification != null) {
        await _psaVerificationService.updateVerification(verification);
      } else {
        await _psaVerificationService.submitVerification(verification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingVerification != null
            ? 'Update Verification'
            : 'Business Verification'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Form Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBusinessProfileStep(),
                _buildBusinessLocationStep(),
                _buildTaxInformationStep(),
                _buildBankAccountStep(),
                _buildPaymentMethodsStep(),
                _buildDocumentsStep(),
              ],
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(6, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 5 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getStepTitle(_currentStep),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Step ${_currentStep + 1} of 6',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Business Profile';
      case 1:
        return 'Business Location';
      case 2:
        return 'Tax Information';
      case 3:
        return 'Bank Account Details';
      case 4:
        return 'Payment Methods';
      case 5:
        return 'Verification Documents';
      default:
        return '';
    }
  }

  Widget _buildBusinessProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your business',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              labelText: 'Legal Business Name *',
              hintText: 'Enter your registered business name',
              prefixIcon: const Icon(Icons.business),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Business Type *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBusinessType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: _businessTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedBusinessType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contactPersonController,
            label: 'Contact Person *',
            hint: 'Full name of contact person',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Contact person is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Business Email *',
            hint: 'example@business.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Business Phone *',
            hint: '+256 700 000000',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where is your business located?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _businessAddressController,
            label: 'Business Address *',
            hint: 'Street address, building name, etc.',
            icon: Icons.location_on,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // District Dropdown
          Text(
            'District *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            hint: const Text('Select District'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.map),
            ),
            items: _districts.map((district) {
              return DropdownMenuItem(
                value: district,
                child: Text(district),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDistrict = value;
                  _selectedSubcounty = null;
                  _selectedParish = null;
                  _selectedVillage = null;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'District is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Subcounty Dropdown
          Text(
            'Subcounty *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSubcounty,
            hint: const Text('Select Subcounty'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.location_city),
            ),
            items: _selectedDistrict == null
                ? []
                : LocationData.getSubcounties(_selectedDistrict!).map((subcounty) {
                    return DropdownMenuItem(
                      value: subcounty,
                      child: Text(subcounty),
                    );
                  }).toList(),
            onChanged: _selectedDistrict == null
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSubcounty = value;
                        _selectedParish = null;
                        _selectedVillage = null;
                      });
                    }
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Subcounty is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Parish Dropdown
          Text(
            'Parish *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedParish,
            hint: const Text('Select Parish'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.home_work),
            ),
            items: _selectedDistrict == null || _selectedSubcounty == null
                ? []
                : LocationData.getParishes(_selectedDistrict!, _selectedSubcounty!).map((parish) {
                    return DropdownMenuItem(
                      value: parish,
                      child: Text(parish),
                    );
                  }).toList(),
            onChanged: _selectedDistrict == null || _selectedSubcounty == null
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedParish = value;
                        _selectedVillage = null;
                      });
                    }
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Parish is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Village Dropdown
          Text(
            'Village *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedVillage,
            hint: const Text('Select Village'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            items: _selectedDistrict == null || _selectedSubcounty == null || _selectedParish == null
                ? []
                : LocationVillageData.getVillages(_selectedDistrict!, _selectedSubcounty!, _selectedParish!).map((village) {
                    return DropdownMenuItem(
                      value: village,
                      child: Text(village),
                    );
                  }).toList(),
            onChanged: _selectedDistrict == null || _selectedSubcounty == null || _selectedParish == null
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedVillage = value;
                      });
                    }
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Village is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // GPS Capture Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'GPS Location (Recommended)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture your business GPS coordinates to help customers find you easily.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_businessLatitude != null && _businessLongitude != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Location Captured',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Latitude: $_businessLatitude',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Longitude: $_businessLongitude',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _isCapturingGPS ? null : _captureGPSLocation,
                  icon: _isCapturingGPS
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _isCapturingGPS
                        ? 'Capturing Location...'
                        : _businessLatitude != null
                            ? 'Update GPS Location'
                            : 'Capture GPS Location',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureGPSLocation() async {
    setState(() => _isCapturingGPS = true);
    
    // Show progress message to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛰️ Searching for GPS signal... This may take up to 45 seconds.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      if (kDebugMode) {
        debugPrint('🌍 Starting GPS location capture...');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        debugPrint('📍 Location service enabled: $serviceEnabled');
      }

      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location in your device settings.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        debugPrint('🔐 Current permission: $permission');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (kDebugMode) {
          debugPrint('🔐 Permission after request: $permission');
        }
        
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied. Please allow location access.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in your browser/device settings.');
      }

      // Get current position with web-compatible settings
      if (kDebugMode) {
        debugPrint('📡 Requesting current position...');
      }

      // Try multiple accuracy levels with progressive fallback
      Position position;
      try {
        // Try 1: High accuracy with 45 second timeout
        if (kDebugMode) {
          debugPrint('📡 Attempt 1: High accuracy GPS...');
        }
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 45),
        );
      } catch (highAccuracyError) {
        if (kDebugMode) {
          debugPrint('⚠️ High accuracy failed: $highAccuracyError');
          debugPrint('📡 Attempt 2: Medium accuracy GPS...');
        }
        try {
          // Try 2: Medium accuracy with 30 second timeout
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 30),
          );
        } catch (mediumAccuracyError) {
          if (kDebugMode) {
            debugPrint('⚠️ Medium accuracy failed: $mediumAccuracyError');
            debugPrint('📡 Attempt 3: Low accuracy GPS (last resort)...');
          }
          // Try 3: Low accuracy with 20 second timeout (last resort)
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 20),
          );
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Position captured: ${position.latitude}, ${position.longitude}');
      }

      setState(() {
        _businessLatitude = position.latitude;
        _businessLongitude = position.longitude;
        _isCapturingGPS = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GPS location captured successfully!\nLat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCapturingGPS = false);
      
      if (kDebugMode) {
        debugPrint('❌ GPS capture error: $e');
      }

      if (mounted) {
        String errorMessage = 'Failed to capture GPS location';
        String details = '';
        
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('denied') || errorStr.contains('permission')) {
          errorMessage = 'Location Permission Required';
          details = 'Please allow location access in your browser when prompted, or check your browser settings.';
        } else if (errorStr.contains('timeout') || errorStr.contains('time')) {
          errorMessage = 'Location Request Timed Out';
          details = 'GPS signal is weak. Please try again in an open area with better signal.';
        } else if (errorStr.contains('unavailable') || errorStr.contains('disabled')) {
          errorMessage = 'Location Services Unavailable';
          details = 'Please enable location services in your device/browser settings and try again.';
        } else if (errorStr.contains('not supported')) {
          errorMessage = 'Location Not Supported';
          details = 'Your browser or device does not support location services.';
        } else {
          details = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'HELP',
              textColor: Colors.white,
              onPressed: () {
                _showGPSHelpDialog();
              },
            ),
          ),
        );
      }
    }
  }

  void _showGPSHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Location Help'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To capture GPS location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildHelpStep('1', 'Allow location access when your browser asks'),
              _buildHelpStep('2', 'Make sure location services are enabled on your device'),
              _buildHelpStep('3', 'Try moving to an area with better GPS signal'),
              _buildHelpStep('4', 'If using a browser, check location permissions in settings'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Note: Location capture works best in standard web browsers (Chrome, Firefox, Safari). It may not work in embedded browsers or some mobile apps.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxInformationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tax Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your business tax details',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _taxIdController,
            label: 'Tax Identification Number (TIN) *',
            hint: 'Enter your business TIN',
            icon: Icons.receipt_long,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tax ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ensure your TIN is accurate. You will need to upload your tax certificate in the documents section.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Account Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where should we send your payments?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _bankAccountHolderController,
            label: 'Account Holder Name *',
            hint: 'Name on bank account',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Account holder name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankAccountNumberController,
            label: 'Account Number *',
            hint: 'Enter your account number',
            icon: Icons.account_balance,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Account number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Bank Name *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              prefixIcon: const Icon(Icons.account_balance),
            ),
            items: _banks.map((bank) {
              return DropdownMenuItem(
                value: bank,
                child: Text(bank),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedBank = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankBranchController,
            label: 'Branch Name *',
            hint: 'Enter bank branch',
            icon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Branch name is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the payment methods you accept',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select at least one payment method *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ..._availablePaymentMethods.map((method) {
            final isSelected = _selectedPaymentMethods.contains(method);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPaymentMethods.remove(method);
                    } else {
                      _selectedPaymentMethods.add(method);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (method == 'Mobile Money')
                              Text(
                                'MTN, Airtel Money',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _getPaymentMethodIcon(method),
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_selectedPaymentMethods.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select at least one payment method',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Mobile Money':
        return Icons.phone_android;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Cash on Delivery':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload all required business documents',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildDocumentUpload(
            title: 'Business License *',
            description: 'Upload your business registration/license',
            file: _businessLicenseFile,
            existingUrl: _businessLicenseUrl,
            onTap: () => _pickImage('business_license'),
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            title: 'Tax Certificate *',
            description: 'Upload your tax registration certificate (TIN)',
            file: _taxIdDocumentFile,
            existingUrl: _taxIdDocumentUrl,
            onTap: () => _pickImage('tax_id'),
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            title: 'National ID *',
            description: 'Upload owner/manager national ID',
            file: _nationalIdFile,
            existingUrl: _nationalIdUrl,
            onTap: () => _pickImage('national_id'),
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            title: 'Trade License *',
            description: 'Upload your trade license',
            file: _tradeLicenseFile,
            existingUrl: _tradeLicenseUrl,
            onTap: () => _pickImage('trade_license'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String description,
    required XFile? file,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    final hasDocument = file != null || existingUrl != null;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: hasDocument ? AppTheme.primaryColor : Colors.grey.shade300,
          width: hasDocument ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasDocument
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.grey.shade50,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasDocument
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            hasDocument ? Icons.check_circle : Icons.upload_file,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          hasDocument ? 'Document uploaded' : description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            hasDocument ? Icons.edit : Icons.add_photo_alternate,
            color: AppTheme.primaryColor,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentStep < 5 ? 'Next' : 'Submit for Review',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
