import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/image_picker_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/nin_validator.dart';
import '../../widgets/location_picker_widget.dart';
import '../../widgets/uganda_phone_field.dart';

class SHGEditProfileScreen extends StatefulWidget {
  const SHGEditProfileScreen({super.key});

  @override
  State<SHGEditProfileScreen> createState() => _SHGEditProfileScreenState();
}

class _SHGEditProfileScreenState extends State<SHGEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _nameOnIdPhotoController = TextEditingController();

  // Partner information controllers
  final _heiferAgrihubNameController = TextEditingController();
  final _heiferSHGNameController = TextEditingController();
  final _heiferSHGIdController = TextEditingController();
  final _heiferParticipantIdController = TextEditingController();
  final _fsmeGroupNameController = TextEditingController();
  final _fsmeGroupIdController = TextEditingController();
  final _fsmeParticipantIdController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  Sex? _selectedSex;
  DisabilityStatus _disabilityStatus = DisabilityStatus.no;
  String? _profileImagePath;
  String? _nationalIdPhotoPath;
  XFile? _profileImageFile; // Local file for display before upload
  XFile? _nationalIdPhotoFile; // Local file for display before upload
  double? _latitude;
  double? _longitude;

  // Location data from picker
  String? _selectedDistrict;
  String? _selectedSubcounty;
  String? _selectedParish;
  String? _selectedVillage;

  // NIN validation state
  String? _ninValidationError;
  String? _ninType;

  // Partner information
  PartnerType? _selectedPartner;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _nationalIdController.text = user.nationalId ?? '';
      _nameOnIdPhotoController.text = user.nameOnIdPhoto ?? '';
      _selectedSex = user.sex;
      _selectedDateOfBirth = user.dateOfBirth;
      _disabilityStatus = user.disabilityStatus;
      _profileImagePath = user.profileImage;
      _nationalIdPhotoPath = user.nationalIdPhoto;

      if (kDebugMode) {
        debugPrint('🔄 SHG EDIT PROFILE - Loaded user data:');
        debugPrint('   - User name: ${user.name}');
        debugPrint('   - Profile image: ${_profileImagePath ?? "NULL"}');
        debugPrint('   - National ID photo: ${_nationalIdPhotoPath ?? "NULL"}');
      }

      // Validate NIN if present
      if (user.nationalId != null && user.nationalId!.isNotEmpty) {
        _validateNIN(user.nationalId!);
      }

      if (user.location != null) {
        // Treat empty strings as null for proper validation
        _selectedDistrict = user.location!.district?.isNotEmpty == true
            ? user.location!.district
            : null;
        _selectedSubcounty = user.location!.subcounty?.isNotEmpty == true
            ? user.location!.subcounty
            : null;
        _selectedParish = user.location!.parish?.isNotEmpty == true
            ? user.location!.parish
            : null;
        _selectedVillage = user.location!.village?.isNotEmpty == true
            ? user.location!.village
            : null;
        _latitude = user.location!.latitude;
        _longitude = user.location!.longitude;
      }

      // Load partner information
      if (user.partnerInfo != null) {
        _selectedPartner = user.partnerInfo!.partner;
        _heiferAgrihubNameController.text =
            user.partnerInfo!.heiferAgrihubName ?? '';
        _heiferSHGNameController.text = user.partnerInfo!.heiferSHGName ?? '';
        _heiferSHGIdController.text = user.partnerInfo!.heiferSHGId ?? '';
        _heiferParticipantIdController.text =
            user.partnerInfo!.heiferParticipantId ?? '';
        _fsmeGroupNameController.text = user.partnerInfo!.fsmeGroupName ?? '';
        _fsmeGroupIdController.text = user.partnerInfo!.fsmeGroupId ?? '';
        _fsmeParticipantIdController.text =
            user.partnerInfo!.fsmeParticipantId ?? '';
      }
    }
  }

  Future<void> _pickImage(bool isProfileImage) async {
    // Use the new ImagePickerService for better UX
    final imagePickerService = ImagePickerService();
    final file = await imagePickerService.showImageSourceBottomSheet(context);

    if (file != null) {
      setState(() {
        if (isProfileImage) {
          _profileImagePath = file.path;
          _profileImageFile = file; // Store XFile for display
        } else {
          _nationalIdPhotoPath = file.path;
          _nationalIdPhotoFile = file; // Store XFile for display
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    // Simulate getting GPS coordinates
    // In production, use geolocator package
    setState(() {
      _latitude = 0.3476; // Kampala default
      _longitude = 32.5825;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates captured'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _validateNIN(String value) {
    setState(() {
      final error = NINValidator.validateNIN(value);
      _ninValidationError = error;

      if (error == null) {
        _ninType = NINValidator.getNINType(value);
      } else {
        _ninType = null;
      }
    });
  }

  /// Build profile image widget that handles both local files and network URLs
  Future<Widget> _buildProfileImage() async {
    if (_profileImageFile != null) {
      // Show local file (newly picked)
      final bytes = await _profileImageFile!.readAsBytes();
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: MemoryImage(bytes),
      );
    } else if (_profileImagePath != null &&
        _profileImagePath!.startsWith('http')) {
      // Show network image (existing URL)
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(_profileImagePath!),
      );
    }

    // No image
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  /// Build national ID photo widget that handles both local files and network URLs
  Future<Widget> _buildNationalIdImage() async {
    if (_nationalIdPhotoFile != null) {
      // Show local file (newly picked)
      final bytes = await _nationalIdPhotoFile!.readAsBytes();
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 150,
      );
    } else if (_nationalIdPhotoPath != null &&
        _nationalIdPhotoPath!.startsWith('http')) {
      // Show network image (existing URL)
      return Image.network(
        _nationalIdPhotoPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 150,
      );
    }

    // No image - show placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            'Tap to add National ID photo',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields for profile completion
    if (_selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your sex'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_nationalIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('National ID is required'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // ✅ National ID photo is now optional during development
    // Users can add GPS location without uploading National ID photo
    // if (_nationalIdPhotoPath == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('National ID photo is required'),
    //       backgroundColor: AppTheme.errorColor,
    //     ),
    //   );
    //   return;
    // }

    // Location validation: Either GPS coordinates OR complete administrative divisions required
    final hasGPS =
        _latitude != null &&
        _longitude != null &&
        _latitude != 0.0 &&
        _longitude != 0.0;
    final hasAdminDivisions =
        _selectedDistrict != null &&
        _selectedDistrict!.isNotEmpty &&
        _selectedSubcounty != null &&
        _selectedSubcounty!.isNotEmpty &&
        _selectedParish != null &&
        _selectedParish!.isNotEmpty &&
        _selectedVillage != null &&
        _selectedVillage!.isNotEmpty;

    if (!hasGPS && !hasAdminDivisions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide either GPS coordinates OR select District/Subcounty/Parish/Village',
          ),
          backgroundColor: AppTheme.errorColor,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create location with either GPS-only or complete administrative divisions
      final location = Location(
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        district: _selectedDistrict,
        subcounty: _selectedSubcounty,
        parish: _selectedParish,
        village: _selectedVillage,
        address: null, // Will be auto-generated from GPS or admin divisions
      );

      // Create partner info if selected
      PartnerInfo? partnerInfo;
      if (_selectedPartner != null) {
        partnerInfo = PartnerInfo(
          partner: _selectedPartner!,
          heiferAgrihubName: _selectedPartner == PartnerType.heifer
              ? _heiferAgrihubNameController.text.trim().isNotEmpty
                    ? _heiferAgrihubNameController.text.trim()
                    : null
              : null,
          heiferSHGName: _selectedPartner == PartnerType.heifer
              ? _heiferSHGNameController.text.trim().isNotEmpty
                    ? _heiferSHGNameController.text.trim()
                    : null
              : null,
          heiferSHGId: _selectedPartner == PartnerType.heifer
              ? _heiferSHGIdController.text.trim().isNotEmpty
                    ? _heiferSHGIdController.text.trim()
                    : null
              : null,
          heiferParticipantId: _selectedPartner == PartnerType.heifer
              ? _heiferParticipantIdController.text.trim().isNotEmpty
                    ? _heiferParticipantIdController.text.trim()
                    : null
              : null,
          fsmeGroupName: _selectedPartner == PartnerType.fsme
              ? _fsmeGroupNameController.text.trim().isNotEmpty
                    ? _fsmeGroupNameController.text.trim()
                    : null
              : null,
          fsmeGroupId: _selectedPartner == PartnerType.fsme
              ? _fsmeGroupIdController.text.trim().isNotEmpty
                    ? _fsmeGroupIdController.text.trim()
                    : null
              : null,
          fsmeParticipantId: _selectedPartner == PartnerType.fsme
              ? _fsmeParticipantIdController.text.trim().isNotEmpty
                    ? _fsmeParticipantIdController.text.trim()
                    : null
              : null,
        );
      }

      if (kDebugMode) {
        debugPrint('📤 SHG EDIT PROFILE - Calling updateProfile with:');
        debugPrint(
          '   - profileImageFile: ${_profileImageFile?.path ?? "null"}',
        );
        debugPrint('   - profileImagePath: ${_profileImagePath ?? "null"}');
        debugPrint(
          '   - nationalIdPhotoFile: ${_nationalIdPhotoFile?.path ?? "null"}',
        );
        debugPrint(
          '   - nationalIdPhotoPath: ${_nationalIdPhotoPath ?? "null"}',
        );
        debugPrint(
          '   - nationalId: ${_nationalIdController.text.trim().isEmpty ? "EMPTY" : "filled"}',
        );
        debugPrint(
          '   - nameOnIdPhoto: ${_nameOnIdPhotoController.text.trim().isEmpty ? "EMPTY" : "filled"}',
        );
        debugPrint('   - sex: ${_selectedSex ?? "null"}');
        debugPrint('   - location: ${location.district}');
        debugPrint(
          '   - partnerInfo: ${partnerInfo != null ? partnerInfo.partner.displayName : "null"}',
        );
      }

      await authProvider.updateProfile(
        profileImageFile: _profileImageFile,
        profileImageUrl: _profileImageFile == null
            ? _profileImagePath
            : null, // Only pass URL if no file
        nationalId: _nationalIdController.text.trim(),
        nationalIdPhotoFile: _nationalIdPhotoFile,
        nationalIdPhotoUrl: _nationalIdPhotoFile == null
            ? _nationalIdPhotoPath
            : null, // Only pass URL if no file
        nameOnIdPhoto: _nameOnIdPhotoController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        sex: _selectedSex,
        disabilityStatus: _disabilityStatus,
        location: location,
        partnerInfo: partnerInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!user!.isProfileComplete)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 16, color: AppTheme.warningColor),
                  const SizedBox(width: 4),
                  Text(
                    'Incomplete',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile completion warning
            if (!user.isProfileComplete)
              Card(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppTheme.warningColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You must complete your profile within 24 hours to start selling. All fields marked with * are required.',
                        style: TextStyle(fontSize: 14),
                      ),
                      if (user.timeRemainingToCompleteProfile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Time remaining: ${_formatDuration(user.timeRemainingToCompleteProfile!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // User ID (Read-only)
            TextFormField(
              initialValue: user.id,
              decoration: const InputDecoration(
                labelText: 'User ID',
                prefixIcon: Icon(Icons.badge),
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),

            // Profile Image
            const Text(
              'Profile Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  FutureBuilder<Widget>(
                    future: _buildProfileImage(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!;
                      }
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        child: const CircularProgressIndicator(),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () => _pickImage(true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone with Uganda validation
            UgandaPhoneField(
              controller: _phoneController,
              required: true,
              showOperatorIcon: true,
              showFormatHelper: true,
              labelText: 'Phone Number *',
            ),
            const SizedBox(height: 16),

            // National ID (NIN) with validation
            TextFormField(
              controller: _nationalIdController,
              decoration: InputDecoration(
                labelText: 'National ID Number (NIN) *',
                prefixIcon: const Icon(Icons.credit_card),
                hintText: 'CM1234567890ABC',
                helperText: 'Format: C or A followed by 13 digits',
                suffixIcon: _ninType != null
                    ? Tooltip(
                        message: _ninType!,
                        child: Icon(
                          Icons.info_outline,
                          color: _ninValidationError == null
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      )
                    : null,
                errorText: _ninValidationError,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: _validateNIN,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'National ID Number (NIN) is required';
                }
                return NINValidator.validateNIN(value);
              },
            ),
            if (_ninType != null && _ninValidationError == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Valid NIN - $_ninType',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // National ID Photo
            const Text(
              'National ID Photo *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickImage(false),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<Widget>(
                    future: _buildNationalIdImage(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!;
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name on ID Photo (for verification)
            TextFormField(
              controller: _nameOnIdPhotoController,
              decoration: InputDecoration(
                labelText: 'Name on ID Photo *',
                prefixIcon: const Icon(Icons.badge),
                hintText: 'Enter name exactly as shown on ID',
                helperText: 'Must match your profile name for verification',
                suffixIcon:
                    _nameController.text.isNotEmpty &&
                        _nameOnIdPhotoController.text.isNotEmpty
                    ? Icon(
                        NINValidator.namesMatch(
                              _nameController.text,
                              _nameOnIdPhotoController.text,
                            )
                            ? Icons.check_circle
                            : Icons.warning,
                        color:
                            NINValidator.namesMatch(
                              _nameController.text,
                              _nameOnIdPhotoController.text,
                            )
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for name match indicator
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name on ID photo is required for verification';
                }
                return null;
              },
            ),
            if (_nameController.text.isNotEmpty &&
                _nameOnIdPhotoController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Row(
                  children: [
                    Icon(
                      NINValidator.namesMatch(
                            _nameController.text,
                            _nameOnIdPhotoController.text,
                          )
                          ? Icons.check_circle
                          : Icons.warning,
                      size: 16,
                      color:
                          NINValidator.namesMatch(
                            _nameController.text,
                            _nameOnIdPhotoController.text,
                          )
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NINValidator.namesMatch(
                            _nameController.text,
                            _nameOnIdPhotoController.text,
                          )
                          ? 'Names match - verification ready'
                          : 'Names do not match - verification may fail',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            NINValidator.namesMatch(
                              _nameController.text,
                              _nameOnIdPhotoController.text,
                            )
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Sex
            DropdownButtonFormField<Sex>(
              initialValue: _selectedSex,
              decoration: const InputDecoration(
                labelText: 'Sex *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: Sex.values.map((sex) {
                return DropdownMenuItem(
                  value: sex,
                  child: Text(sex.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSex = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your sex';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateOfBirth ?? DateTime(2000),
                  firstDate: DateTime(1924),
                  lastDate: DateTime.now(),
                  helpText: 'Select your date of birth',
                );
                if (picked != null) {
                  setState(() {
                    _selectedDateOfBirth = picked;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: _selectedDateOfBirth != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedDateOfBirth = null;
                              });
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                        : '',
                  ),
                  validator: (value) {
                    if (_selectedDateOfBirth == null) {
                      return 'Please select your date of birth';
                    }
                    // Check if user is at least 18 years old
                    final age = DateTime.now().difference(_selectedDateOfBirth!).inDays ~/ 365;
                    if (age < 18) {
                      return 'You must be at least 18 years old';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Disability Status
            const Text(
              'Disability Status *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            RadioGroup<DisabilityStatus>(
              groupValue: _disabilityStatus,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _disabilityStatus = value;
                  });
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<DisabilityStatus>(
                      title: const Text('No'),
                      value: DisabilityStatus.no,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<DisabilityStatus>(
                      title: const Text('Yes (PWD)'),
                      value: DisabilityStatus.yes,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Partner Information Section
            const Divider(height: 32),
            const Text(
              'Partner Information (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your partner organization if applicable. This helps us track program effectiveness.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Partner Dropdown
            DropdownButtonFormField<PartnerType>(
              initialValue: _selectedPartner,
              decoration: const InputDecoration(
                labelText: 'Partner Organization',
                prefixIcon: Icon(Icons.business),
                hintText: 'Select partner (optional)',
              ),
              items: PartnerType.values.map((partner) {
                return DropdownMenuItem(
                  value: partner,
                  child: Text(partner.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPartner = value;
                  // Clear fields when partner changes
                  if (value != PartnerType.heifer) {
                    _heiferAgrihubNameController.clear();
                    _heiferSHGNameController.clear();
                    _heiferSHGIdController.clear();
                    _heiferParticipantIdController.clear();
                  }
                  if (value != PartnerType.fsme) {
                    _fsmeGroupNameController.clear();
                    _fsmeGroupIdController.clear();
                    _fsmeParticipantIdController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Heifer-specific fields
            if (_selectedPartner == PartnerType.heifer) ...[
              TextFormField(
                controller: _heiferAgrihubNameController,
                decoration: const InputDecoration(
                  labelText: 'Heifer Agrihub Name',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heiferSHGNameController,
                decoration: const InputDecoration(
                  labelText: 'Heifer SHG Name',
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heiferSHGIdController,
                decoration: const InputDecoration(
                  labelText: 'Heifer SHG ID',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heiferParticipantIdController,
                decoration: const InputDecoration(
                  labelText: 'Heifer Participant ID',
                  prefixIcon: Icon(Icons.person_pin),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // FSME-specific fields
            if (_selectedPartner == PartnerType.fsme) ...[
              TextFormField(
                controller: _fsmeGroupNameController,
                decoration: const InputDecoration(
                  labelText: 'FSME Group Name',
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fsmeGroupIdController,
                decoration: const InputDecoration(
                  labelText: 'FSME Group ID',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fsmeParticipantIdController,
                decoration: const InputDecoration(
                  labelText: 'FSME Participant ID',
                  prefixIcon: Icon(Icons.person_pin),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Location Section
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Location Information *',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get GPS'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cascading Location Picker
            LocationPickerWidget(
              initialDistrict: _selectedDistrict,
              initialSubcounty: _selectedSubcounty,
              initialParish: _selectedParish,
              initialVillage: _selectedVillage,
              onLocationChanged: (district, subcounty, parish, village) {
                setState(() {
                  _selectedDistrict = district;
                  _selectedSubcounty = subcounty;
                  _selectedParish = parish;
                  _selectedVillage = village;
                });
              },
            ),
            const SizedBox(height: 16),

            // GPS Coordinates (Read-only)
            if (_latitude != null && _longitude != null)
              Card(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS Coordinates',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Profile'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _nameOnIdPhotoController.dispose();
    _heiferAgrihubNameController.dispose();
    _heiferSHGNameController.dispose();
    _heiferSHGIdController.dispose();
    _heiferParticipantIdController.dispose();
    _fsmeGroupNameController.dispose();
    _fsmeGroupIdController.dispose();
    _fsmeParticipantIdController.dispose();
    super.dispose();
  }
}
