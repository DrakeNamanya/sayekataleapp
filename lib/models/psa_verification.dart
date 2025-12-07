/// PSA (Private Service Aggregator) verification request model
class PsaVerification {
  final String id;
  final String psaId; // Custom PSA ID (e.g., PSA-12345)
  final String? userId; // Firebase Auth UID (for Firestore rules)
  final String businessName;
  final String contactPerson;
  final String email;
  final String phoneNumber;
  final String businessAddress;
  final String businessType; // e.g., "Input Supplier", "Equipment Rental"

  // Business location details (hierarchical)
  final String? businessDistrict;
  final String? businessSubcounty;
  final String? businessParish;
  final String? businessVillage;
  final double? businessLatitude;
  final double? businessLongitude;

  // Tax information
  final String? taxId; // Tax Identification Number (TIN)

  // Bank account details
  final String? bankAccountHolderName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankBranch;

  // Payment methods
  final List<String>
  paymentMethods; // e.g., ["Mobile Money", "Bank Transfer", "Cash"]

  // Business registration documents
  final String? businessLicenseUrl;
  final String? taxIdDocumentUrl;
  final String? nationalIdUrl;
  final String? tradeLicenseUrl;

  // Additional verification documents
  final List<String> additionalDocuments;

  // Verification details
  final PsaVerificationStatus status;
  final String? rejectionReason;
  final String? reviewNotes;
  final String? reviewedBy; // Admin ID
  final DateTime? reviewedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  PsaVerification({
    required this.id,
    required this.psaId,
    this.userId,
    required this.businessName,
    required this.contactPerson,
    required this.email,
    required this.phoneNumber,
    required this.businessAddress,
    required this.businessType,
    this.businessDistrict,
    this.businessSubcounty,
    this.businessParish,
    this.businessVillage,
    this.businessLatitude,
    this.businessLongitude,
    this.taxId,
    this.bankAccountHolderName,
    this.bankAccountNumber,
    this.bankName,
    this.bankBranch,
    this.paymentMethods = const [],
    this.businessLicenseUrl,
    this.taxIdDocumentUrl,
    this.nationalIdUrl,
    this.tradeLicenseUrl,
    this.additionalDocuments = const [],
    this.status = PsaVerificationStatus.pending,
    this.rejectionReason,
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PsaVerification.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return PsaVerification(
      id: id,
      psaId: data['psa_id'] ?? '',
      userId: data['userId'], // Firebase Auth UID
      businessName: data['business_name'] ?? '',
      contactPerson: data['contact_person'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      businessAddress: data['business_address'] ?? '',
      businessType: data['business_type'] ?? '',
      businessDistrict: data['business_district'],
      businessSubcounty: data['business_subcounty'],
      businessParish: data['business_parish'],
      businessVillage: data['business_village'],
      businessLatitude: data['business_latitude']?.toDouble(),
      businessLongitude: data['business_longitude']?.toDouble(),
      taxId: data['tax_id'],
      bankAccountHolderName: data['bank_account_holder_name'],
      bankAccountNumber: data['bank_account_number'],
      bankName: data['bank_name'],
      bankBranch: data['bank_branch'],
      paymentMethods: data['payment_methods'] != null
          ? List<String>.from(data['payment_methods'])
          : [],
      businessLicenseUrl: data['business_license_url'],
      taxIdDocumentUrl: data['tax_id_document_url'],
      nationalIdUrl: data['national_id_url'],
      tradeLicenseUrl: data['trade_license_url'],
      additionalDocuments: data['additional_documents'] != null
          ? List<String>.from(data['additional_documents'])
          : [],
      status: PsaVerificationStatus.values.firstWhere(
        (e) => e.toString() == 'PsaVerificationStatus.${data['status']}',
        orElse: () => PsaVerificationStatus.pending,
      ),
      rejectionReason: data['rejection_reason'],
      reviewNotes: data['review_notes'],
      reviewedBy: data['reviewed_by'],
      reviewedAt: data['reviewed_at'] != null
          ? parseDateTime(data['reviewed_at'])
          : null,
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'psa_id': psaId,
      'userId': userId, // Firebase Auth UID for Firestore rules
      'business_name': businessName,
      'contact_person': contactPerson,
      'email': email,
      'phone_number': phoneNumber,
      'business_address': businessAddress,
      'business_type': businessType,
      'business_district': businessDistrict,
      'business_subcounty': businessSubcounty,
      'business_parish': businessParish,
      'business_village': businessVillage,
      'business_latitude': businessLatitude,
      'business_longitude': businessLongitude,
      'tax_id': taxId,
      'bank_account_holder_name': bankAccountHolderName,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'payment_methods': paymentMethods,
      'business_license_url': businessLicenseUrl,
      'tax_id_document_url': taxIdDocumentUrl,
      'national_id_url': nationalIdUrl,
      'trade_license_url': tradeLicenseUrl,
      'additional_documents': additionalDocuments,
      'status': status.toString().split('.').last,
      'rejection_reason': rejectionReason,
      'review_notes': reviewNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if all required documents are submitted
  bool get hasAllRequiredDocuments {
    return businessLicenseUrl != null &&
        taxIdDocumentUrl != null &&
        nationalIdUrl != null &&
        tradeLicenseUrl != null;
  }

  /// Get list of missing documents
  List<String> get missingDocuments {
    final missing = <String>[];
    if (businessLicenseUrl == null) missing.add('Business License');
    if (taxIdDocumentUrl == null) missing.add('Tax ID Document');
    if (nationalIdUrl == null) missing.add('National ID');
    if (tradeLicenseUrl == null) missing.add('Trade License');
    return missing;
  }

  /// Check if all mandatory profile information is complete
  bool get hasAllMandatoryFields {
    return businessName.isNotEmpty &&
        contactPerson.isNotEmpty &&
        email.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        businessAddress.isNotEmpty &&
        businessType.isNotEmpty &&
        businessDistrict != null &&
        businessDistrict!.isNotEmpty &&
        taxId != null &&
        taxId!.isNotEmpty &&
        bankAccountHolderName != null &&
        bankAccountHolderName!.isNotEmpty &&
        bankAccountNumber != null &&
        bankAccountNumber!.isNotEmpty &&
        bankName != null &&
        bankName!.isNotEmpty &&
        paymentMethods.isNotEmpty;
  }

  /// Get list of missing mandatory fields
  List<String> get missingMandatoryFields {
    final missing = <String>[];
    if (businessName.isEmpty) missing.add('Business Name');
    if (contactPerson.isEmpty) missing.add('Contact Person');
    if (email.isEmpty) missing.add('Email');
    if (phoneNumber.isEmpty) missing.add('Phone Number');
    if (businessAddress.isEmpty) missing.add('Business Address');
    if (businessType.isEmpty) missing.add('Business Type');
    if (businessDistrict == null || businessDistrict!.isEmpty) {
      missing.add('Business District');
    }
    if (taxId == null || taxId!.isEmpty) {
      missing.add('Tax ID');
    }
    if (bankAccountHolderName == null || bankAccountHolderName!.isEmpty) {
      missing.add('Bank Account Holder');
    }
    if (bankAccountNumber == null || bankAccountNumber!.isEmpty) {
      missing.add('Bank Account Number');
    }
    if (bankName == null || bankName!.isEmpty) missing.add('Bank Name');
    if (paymentMethods.isEmpty) missing.add('Payment Methods');
    return missing;
  }

  /// Calculate profile completion percentage (0-100)
  int get profileCompletionPercentage {
    int total = 12; // Total mandatory fields
    int completed = 0;

    if (businessName.isNotEmpty) completed++;
    if (contactPerson.isNotEmpty) completed++;
    if (email.isNotEmpty) completed++;
    if (phoneNumber.isNotEmpty) completed++;
    if (businessAddress.isNotEmpty) completed++;
    if (businessType.isNotEmpty) completed++;
    if (businessDistrict != null && businessDistrict!.isNotEmpty) completed++;
    if (taxId != null && taxId!.isNotEmpty) completed++;
    if (bankAccountHolderName != null && bankAccountHolderName!.isNotEmpty)
      completed++;
    if (bankAccountNumber != null && bankAccountNumber!.isNotEmpty) completed++;
    if (bankName != null && bankName!.isNotEmpty) completed++;
    if (paymentMethods.isNotEmpty) completed++;

    return ((completed / total) * 100).round();
  }
}

enum PsaVerificationStatus {
  pending, // Awaiting admin review
  underReview, // Admin is reviewing
  approved, // Verified and approved
  rejected, // Rejected with reason
  moreInfoRequired, // Needs additional documents
}

extension PsaVerificationStatusExtension on PsaVerificationStatus {
  String get displayName {
    switch (this) {
      case PsaVerificationStatus.pending:
        return 'Pending Review';
      case PsaVerificationStatus.underReview:
        return 'Under Review';
      case PsaVerificationStatus.approved:
        return 'Approved';
      case PsaVerificationStatus.rejected:
        return 'Rejected';
      case PsaVerificationStatus.moreInfoRequired:
        return 'More Info Required';
    }
  }

  bool get canReview {
    return this == PsaVerificationStatus.pending ||
        this == PsaVerificationStatus.moreInfoRequired;
  }

  bool get isApproved => this == PsaVerificationStatus.approved;
  bool get isRejected => this == PsaVerificationStatus.rejected;
  bool get isPending =>
      this == PsaVerificationStatus.pending ||
      this == PsaVerificationStatus.underReview;
}
