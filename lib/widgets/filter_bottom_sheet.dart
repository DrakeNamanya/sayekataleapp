import 'package:flutter/material.dart';
import '../models/browse_filter.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../constants/uganda_districts.dart';

class FilterBottomSheet extends StatefulWidget {
  final BrowseFilter initialFilter;

  const FilterBottomSheet({super.key, required this.initialFilter});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<String> _selectedCategories;
  late Set<String> _selectedDistricts;
  late double _minPrice;
  late double _maxPrice;
  late double _selectedDistance;
  late double? _selectedRating;
  late bool _inStockOnly;

  // Price range constraints
  static const double minPriceLimit = 0;
  static const double maxPriceLimit = 100; // in thousands (100K)

  // Distance options (in km)
  static const List<double> distanceOptions = [5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.initialFilter.selectedCategories);
    _selectedDistricts = Set.from(widget.initialFilter.selectedDistricts);
    _minPrice = widget.initialFilter.minPrice ?? minPriceLimit;
    _maxPrice = widget.initialFilter.maxPrice ?? maxPriceLimit;
    _selectedDistance = widget.initialFilter.maxDistance ?? 50;
    _selectedRating = widget.initialFilter.minRating;
    _inStockOnly = widget.initialFilter.inStockOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryFilter(),
                  const SizedBox(height: 24),
                  _buildDistrictFilter(),
                  const SizedBox(height: 24),
                  _buildPriceFilter(),
                  const SizedBox(height: 24),
                  _buildDistanceFilter(),
                  const SizedBox(height: 24),
                  _buildRatingFilter(),
                  const SizedBox(height: 24),
                  _buildStockFilter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.category, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ProductCategory.values.map((category) {
            final isSelected = _selectedCategories.contains(category.name);
            return FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category.name);
                  } else {
                    _selectedCategories.remove(category.name);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDistrictFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_city, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Districts (12 Official Districts)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UgandaDistricts.allDistricts.map((district) {
            final isSelected = _selectedDistricts.contains(district);
            return FilterChip(
              label: Text(
                district,
                style: const TextStyle(fontSize: 12),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDistricts.add(district);
                  } else {
                    _selectedDistricts.remove(district);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.attach_money, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Price Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'UGX ${_minPrice.toInt()}K',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'UGX ${_maxPrice.toInt()}K',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: minPriceLimit,
          max: maxPriceLimit,
          divisions: 20,
          labels: RangeLabels('${_minPrice.toInt()}K', '${_maxPrice.toInt()}K'),
          onChanged: (RangeValues values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Maximum Distance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: distanceOptions.map((distance) {
            final isSelected = _selectedDistance == distance;
            return ChoiceChip(
              label: Text('${distance.toInt()} km'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDistance = distance;
                });
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final ratingOptions = [
      {'value': null, 'label': 'All', 'icon': '⭐'},
      {'value': 3.0, 'label': '3+ Stars', 'icon': '⭐⭐⭐'},
      {'value': 4.0, 'label': '4+ Stars', 'icon': '⭐⭐⭐⭐'},
      {'value': 4.5, 'label': '4.5+ Stars', 'icon': '⭐⭐⭐⭐⭐'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.star, size: 20, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Minimum Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ratingOptions.map((option) {
            final isSelected = _selectedRating == option['value'];
            return ChoiceChip(
              label: Text(option['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedRating = option['value'] as double?;
                });
              },
              selectedColor: Colors.amber[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockFilter() {
    return Row(
      children: [
        const Icon(Icons.inventory_2, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        const Text(
          'Stock Availability',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Switch(
          value: _inStockOnly,
          onChanged: (value) {
            setState(() {
              _inStockOnly = value;
            });
          },
          activeTrackColor: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          _inStockOnly ? 'In Stock Only' : 'All Products',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedDistricts.clear();
      _minPrice = minPriceLimit;
      _maxPrice = maxPriceLimit;
      _selectedDistance = 50;
      _selectedRating = null;
      _inStockOnly = false;
    });
  }

  void _applyFilters() {
    final filter = BrowseFilter(
      selectedCategories: _selectedCategories,
      selectedDistricts: _selectedDistricts,
      minPrice: _minPrice > minPriceLimit ? _minPrice : null,
      maxPrice: _maxPrice < maxPriceLimit ? _maxPrice : null,
      maxDistance: _selectedDistance,
      minRating: _selectedRating,
      inStockOnly: _inStockOnly,
    );

    Navigator.pop(context, filter);
  }
}
