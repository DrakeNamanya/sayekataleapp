import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../utils/app_theme.dart';
import '../../widgets/location_picker_widget.dart';
import '../../widgets/uganda_phone_field.dart';

class PSAEditProfileScreen extends StatefulWidget {
  const PSAEditProfileScreen({super.key});

  @override
  State<PSAEditProfileScreen> createState() => _PSAEditProfileScreenState();
}

class _PSAEditProfileScreenState extends State<PSAEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Business Information Controllers
  final _businessNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tinNumberController = TextEditingController();
  final _unbsRegistrationController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  
  // Business Start Date
  DateTime? _businessStartDate;
  
  // Photo paths
  String? _profileImagePath;
  String? _signpostPhotoPath;
  String? _registrationCertPhotoPath;
  final List<String> _storePhotos = [];
  
  // Location
  String? _selectedDistrict;
  String? _selectedSubcounty;
  String? _selectedParish;
  String? _selectedVillage;
  double? _latitude;
  double? _longitude;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBusinessData();
  }

  Future<void> _loadCurrentBusinessData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      setState(() {
        _businessNameController.text = user.name;
        _phoneController.text = user.phone;
        _profileImagePath = user.profileImage;
        
        if (user.location != null) {
          _selectedDistrict = user.location!.district;
          _selectedSubcounty = user.location!.subcounty;
          _selectedParish = user.location!.parish;
          _selectedVillage = user.location!.village;
          _latitude = user.location!.latitude;
          _longitude = user.location!.longitude;
        }
        
        // TODO: Load additional business fields from user model when available
        // _legalNameController.text = user.businessLegalName ?? '';
        // _tinNumberController.text = user.tinNumber ?? '';
        // etc.
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _phoneController.dispose();
    _tinNumberController.dispose();
    _unbsRegistrationController.dispose();
    _mobileMoneyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        switch (imageType) {
          case 'profile':
            _profileImagePath = pickedFile.path;
            break;
          case 'signpost':
            _signpostPhotoPath = pickedFile.path;
            break;
          case 'certificate':
            _registrationCertPhotoPath = pickedFile.path;
            break;
          case 'store':
            if (_storePhotos.length < 5) { // Limit to 5 store photos
              _storePhotos.add(pickedFile.path);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 5 store photos allowed'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            }
            break;
        }
      });
    }
  }

  Future<void> _selectBusinessStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _businessStartDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _businessStartDate = date;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate location
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

      // TODO: Update this when business fields are added to user model
      await authProvider.updateProfile(
        profileImage: _profileImagePath,
        location: location,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Image
            const Text(
              'Business Logo/Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage('profile'),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _profileImagePath != null
                      ? ClipOval(
                          child: Image.network(
                            _profileImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.add_a_photo, size: 48, color: AppTheme.primaryColor);
                            },
                          ),
                        )
                      : const Icon(Icons.add_a_photo, size: 48, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Business Name
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                prefixIcon: Icon(Icons.business),
                hintText: 'e.g., Agro Supplies Ltd',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Legal Name of Business
            TextFormField(
              controller: _legalNameController,
              decoration: const InputDecoration(
                labelText: 'Legal Name of Business *',
                prefixIcon: Icon(Icons.gavel),
                hintText: 'Official registered business name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Legal business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Business Start Date
            InkWell(
              onTap: _selectBusinessStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Business Start *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _businessStartDate != null
                      ? '${_businessStartDate!.day}/${_businessStartDate!.month}/${_businessStartDate!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: _businessStartDate != null 
                        ? AppTheme.textPrimary 
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TIN Number
            TextFormField(
              controller: _tinNumberController,
              decoration: const InputDecoration(
                labelText: 'TIN Number (Tax Identification Number) *',
                prefixIcon: Icon(Icons.assignment_outlined),
                hintText: 'Enter TIN number',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'TIN number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // UNBS Registration Number
            TextFormField(
              controller: _unbsRegistrationController,
              decoration: const InputDecoration(
                labelText: 'UNBS Registration Number *',
                prefixIcon: Icon(Icons.verified_outlined),
                hintText: 'Uganda National Bureau of Standards',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'UNBS registration number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact Phone with Uganda validation
            UgandaPhoneField(
              controller: _phoneController,
              required: true,
              showOperatorIcon: true,
              showFormatHelper: true,
              labelText: 'Business Phone Number *',
            ),
            const SizedBox(height: 16),

            // Mobile Money Payment Number with Uganda validation
            UgandaPhoneField(
              controller: _mobileMoneyController,
              required: true,
              showOperatorIcon: true,
              showFormatHelper: true,
              labelText: 'Mobile Money Payment Number *',
              helperText: 'For receiving payments from customers',
            ),
            const SizedBox(height: 24),

            // Signpost Photo
            const Text(
              'Business Signpost Photo *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage('signpost'),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _signpostPhotoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _signpostPhotoPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text('Tap to upload signpost photo', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            );
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Tap to upload signpost photo', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Registration Certificate Photo
            const Text(
              'Registration Certificate Photo *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage('certificate'),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _registrationCertPhotoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _registrationCertPhotoPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text('Tap to upload certificate', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            );
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Tap to upload certificate', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Store Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Store Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${_storePhotos.length}/5',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add Photo Button
                  GestureDetector(
                    onTap: () => _pickImage('store'),
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey.shade600),
                          const SizedBox(height: 4),
                          Text('Add Photo', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                  // Existing Photos
                  ..._storePhotos.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              entry.value,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _storePhotos.removeAt(entry.key);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location Section
            const Text(
              'Business Location (GPS) *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
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

            // GPS Coordinates (if available)
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
                  : const Text('Save Business Profile'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
