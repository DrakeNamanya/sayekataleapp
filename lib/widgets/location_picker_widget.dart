import 'package:flutter/material.dart';
import '../models/uganda_location_data.dart';

/// Cascading Location Picker Widget
/// Provides hierarchical dropdowns for District -> Subcounty -> Parish -> Village
class LocationPickerWidget extends StatefulWidget {
  final String? initialDistrict;
  final String? initialSubcounty;
  final String? initialParish;
  final String? initialVillage;
  final Function(String? district, String? subcounty, String? parish, String? village) onLocationChanged;

  const LocationPickerWidget({
    super.key,
    this.initialDistrict,
    this.initialSubcounty,
    this.initialParish,
    this.initialVillage,
    required this.onLocationChanged,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  String? _selectedDistrict;
  String? _selectedSubcounty;
  String? _selectedParish;
  String? _selectedVillage;

  List<String> _districts = [];
  List<String> _subcounties = [];
  List<String> _parishes = [];
  List<String> _villages = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Load all districts
    _districts = UgandaLocationData.getDistricts();

    // Set initial values if provided
    if (widget.initialDistrict != null && 
        _districts.contains(widget.initialDistrict)) {
      _selectedDistrict = widget.initialDistrict;
      _loadSubcounties(_selectedDistrict!);

      if (widget.initialSubcounty != null && 
          _subcounties.contains(widget.initialSubcounty)) {
        _selectedSubcounty = widget.initialSubcounty;
        _loadParishes(_selectedDistrict!, _selectedSubcounty!);

        if (widget.initialParish != null && 
            _parishes.contains(widget.initialParish)) {
          _selectedParish = widget.initialParish;
          _loadVillages(_selectedDistrict!, _selectedSubcounty!, _selectedParish!);

          if (widget.initialVillage != null && 
              _villages.contains(widget.initialVillage)) {
            _selectedVillage = widget.initialVillage;
          }
        }
      }
    }
  }

  void _loadSubcounties(String district) {
    setState(() {
      _subcounties = UgandaLocationData.getSubcounties(district);
      _selectedSubcounty = null;
      _parishes = [];
      _selectedParish = null;
      _villages = [];
      _selectedVillage = null;
    });
    _notifyChange();
  }

  void _loadParishes(String district, String subcounty) {
    setState(() {
      _parishes = UgandaLocationData.getParishes(district, subcounty);
      _selectedParish = null;
      _villages = [];
      _selectedVillage = null;
    });
    _notifyChange();
  }

  void _loadVillages(String district, String subcounty, String parish) {
    setState(() {
      _villages = UgandaLocationData.getVillages(district, subcounty, parish);
      _selectedVillage = null;
    });
    _notifyChange();
  }

  void _notifyChange() {
    widget.onLocationChanged(
      _selectedDistrict,
      _selectedSubcounty,
      _selectedParish,
      _selectedVillage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District Dropdown
        _buildDropdown(
          label: 'District',
          value: _selectedDistrict,
          items: _districts,
          hint: 'Select District',
          onChanged: (value) {
            setState(() {
              _selectedDistrict = value;
            });
            if (value != null) {
              _loadSubcounties(value);
            }
          },
        ),
        const SizedBox(height: 16),

        // Subcounty Dropdown
        _buildDropdown(
          label: 'Subcounty/Town',
          value: _selectedSubcounty,
          items: _subcounties,
          hint: 'Select Subcounty',
          enabled: _selectedDistrict != null,
          onChanged: (value) {
            setState(() {
              _selectedSubcounty = value;
            });
            if (value != null && _selectedDistrict != null) {
              _loadParishes(_selectedDistrict!, value);
            }
          },
        ),
        const SizedBox(height: 16),

        // Parish Dropdown
        _buildDropdown(
          label: 'Parish',
          value: _selectedParish,
          items: _parishes,
          hint: 'Select Parish',
          enabled: _selectedSubcounty != null,
          onChanged: (value) {
            setState(() {
              _selectedParish = value;
            });
            if (value != null && _selectedDistrict != null && _selectedSubcounty != null) {
              _loadVillages(_selectedDistrict!, _selectedSubcounty!, value);
            }
          },
        ),
        const SizedBox(height: 16),

        // Village Dropdown
        _buildDropdown(
          label: 'Village',
          value: _selectedVillage,
          items: _villages,
          hint: 'Select Village',
          enabled: _selectedParish != null,
          onChanged: (value) {
            setState(() {
              _selectedVillage = value;
            });
            _notifyChange();
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items.isEmpty
                  ? null
                  : items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
