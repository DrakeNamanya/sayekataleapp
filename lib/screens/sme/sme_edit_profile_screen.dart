import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../utils/app_theme.dart';
import '../../utils/nin_validator.dart';
import '../../widgets/location_picker_widget.dart';
import '../../widgets/uganda_phone_field.dart';

class SMEEditProfileScreen extends StatefulWidget {
  const SMEEditProfileScreen({super.key});

  @override
  State<SMEEditProfileScreen> createState() => _SMEEditProfileScreenState();
}

class _SMEEditProfileScreenState extends State<SMEEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _nameOnIdPhotoController = TextEditingController();
  
  Sex? _selectedSex;
  DisabilityStatus _disabilityStatus = DisabilityStatus.no;
  String? _profileImagePath;
  String? _nationalIdPhotoPath;
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
      _disabilityStatus = user.disabilityStatus;
      _profileImagePath = user.profileImage;
      _nationalIdPhotoPath = user.nationalIdPhoto;
      
      // Validate NIN if present
      if (user.nationalId != null && user.nationalId!.isNotEmpty) {
        _validateNIN(user.nationalId!);
      }
      
      if (user.location != null) {
        _selectedDistrict = user.location!.district;
        _selectedSubcounty = user.location!.subcounty;
        _selectedParish = user.location!.parish;
        _selectedVillage = user.location!.village;
        _latitude = user.location!.latitude;
        _longitude = user.location!.longitude;
      }
    }
  }

  Future<void> _pickImage(bool isProfileImage) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (isProfileImage) {
          _profileImagePath = image.path;
        } else {
          _nationalIdPhotoPath = image.path;
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

  Future<void> _saveProfile() async{
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

    if (_nationalIdPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('National ID photo is required'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedDistrict == null || 
        _selectedSubcounty == null ||
        _selectedParish == null ||
        _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete location information is required'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final location = Location(
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        district: _selectedDistrict!,
        subcounty: _selectedSubcounty!,
        parish: _selectedParish!,
        village: _selectedVillage!,
      );

      await authProvider.updateProfile(
        profileImage: _profileImagePath,
        nationalId: _nationalIdController.text.trim(),
        nationalIdPhoto: _nationalIdPhotoPath,
        nameOnIdPhoto: _nameOnIdPhotoController.text.trim(),
        sex: _selectedSex,
        disabilityStatus: _disabilityStatus,
        location: location,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImagePath != null
                        ? NetworkImage(_profileImagePath!) as ImageProvider
                        : null,
                    child: _profileImagePath == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
                child: _nationalIdPhotoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _nationalIdPhotoPath!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload National ID photo',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Name on ID Photo with matching indicator
            TextFormField(
              controller: _nameOnIdPhotoController,
              decoration: InputDecoration(
                labelText: 'Name on ID Photo *',
                prefixIcon: const Icon(Icons.badge),
                hintText: 'Enter name exactly as shown on National ID',
                helperText: 'Must match your profile name for verification',
                helperMaxLines: 2,
                suffixIcon: _nameOnIdPhotoController.text.isNotEmpty && _nameController.text.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          final namesMatch = NINValidator.namesMatch(
                            _nameOnIdPhotoController.text,
                            _nameController.text,
                          );
                          final similarity = NINValidator.calculateNameSimilarity(
                            _nameOnIdPhotoController.text,
                            _nameController.text,
                          );
                          
                          IconData icon;
                          Color color;
                          String message;
                          
                          if (namesMatch) {
                            icon = Icons.check_circle;
                            color = AppTheme.successColor;
                            message = 'Names match perfectly';
                          } else if (similarity >= 0.7) {
                            icon = Icons.warning;
                            color = AppTheme.warningColor;
                            message = 'Names are similar but not exact match';
                          } else {
                            icon = Icons.error;
                            color = AppTheme.errorColor;
                            message = 'Names do not match - verification may fail';
                          }
                          
                          return Tooltip(
                            message: message,
                            child: Icon(icon, color: color),
                          );
                        },
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {}); // Trigger rebuild for suffix icon
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name on ID Photo is required for verification';
                }
                
                // Check name similarity with profile name
                if (_nameController.text.isNotEmpty) {
                  final similarity = NINValidator.calculateNameSimilarity(
                    value,
                    _nameController.text,
                  );
                  
                  if (similarity < 0.5) {
                    return 'Name differs significantly from profile name';
                  }
                }
                
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Sex
            DropdownButtonFormField<Sex>(
              value: _selectedSex,
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

            // Disability Status
            const Text(
              'Disability Status *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<DisabilityStatus>(
                    title: const Text('No'),
                    value: DisabilityStatus.no,
                    groupValue: _disabilityStatus,
                    onChanged: (value) {
                      setState(() {
                        _disabilityStatus = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<DisabilityStatus>(
                    title: const Text('Yes (PWD)'),
                    value: DisabilityStatus.yes,
                    groupValue: _disabilityStatus,
                    onChanged: (value) {
                      setState(() {
                        _disabilityStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Section
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Location Information *',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
    super.dispose();
  }
}
