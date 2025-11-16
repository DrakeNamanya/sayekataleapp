import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PSAInventoryScreen extends StatefulWidget {
  const PSAInventoryScreen({super.key});

  @override
  State<PSAInventoryScreen> createState() => _PSAInventoryScreenState();
}

class MutableProduct {
  final String id;
  final String name;
  final String? description;
  final String unit;
  int stockQuantity;
  final int lowStockThreshold;

  MutableProduct({
    required this.id,
    required this.name,
    this.description,
    required this.unit,
    required this.stockQuantity,
    required this.lowStockThreshold,
  });
}

class _PSAInventoryScreenState extends State<PSAInventoryScreen> {
  // Mock inventory data (in production, fetch from API/database)
  final List<MutableProduct> _inventory = [
    MutableProduct(
      id: 'psa_crop1',
      name: 'Hybrid Maize Seeds',
      description: 'High-yield hybrid maize seeds, 10kg bag',
      unit: 'bag',
      stockQuantity: 200,
      lowStockThreshold: 50,
    ),
    MutableProduct(
      id: 'psa_crop2',
      name: 'NPK Fertilizer',
      description: 'NPK 17-17-17 compound fertilizer, 50kg bag',
      unit: 'bag',
      stockQuantity: 35, // Low stock
      lowStockThreshold: 50,
    ),
    MutableProduct(
      id: 'psa_crop3',
      name: 'Pesticide Spray',
      description: 'Multi-purpose pesticide, 1 liter',
      unit: 'liter',
      stockQuantity: 0, // Out of stock
      lowStockThreshold: 20,
    ),
  ];

  String _filterType = 'all'; // all, low_stock, out_of_stock

  List<MutableProduct> get _filteredInventory {
    switch (_filterType) {
      case 'low_stock':
        return _inventory
            .where(
              (p) =>
                  p.stockQuantity > 0 && p.stockQuantity <= p.lowStockThreshold,
            )
            .toList();
      case 'out_of_stock':
        return _inventory.where((p) => p.stockQuantity == 0).toList();
      default:
        return _inventory;
    }
  }

  int get _lowStockCount => _inventory
      .where(
        (p) => p.stockQuantity > 0 && p.stockQuantity <= p.lowStockThreshold,
      )
      .length;

  int get _outOfStockCount =>
      _inventory.where((p) => p.stockQuantity == 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Management')),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Items',
                    value: _inventory.length.toString(),
                    icon: Icons.inventory_2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Low Stock',
                    value: _lowStockCount.toString(),
                    icon: Icons.warning_amber,
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Out of Stock',
                    value: _outOfStockCount.toString(),
                    icon: Icons.error_outline,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All Products',
                  count: _inventory.length,
                  isSelected: _filterType == 'all',
                  onTap: () => setState(() => _filterType = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low Stock',
                  count: _lowStockCount,
                  isSelected: _filterType == 'low_stock',
                  color: AppTheme.warningColor,
                  onTap: () => setState(() => _filterType = 'low_stock'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Out of Stock',
                  count: _outOfStockCount,
                  isSelected: _filterType == 'out_of_stock',
                  color: AppTheme.errorColor,
                  onTap: () => setState(() => _filterType = 'out_of_stock'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Inventory List
          Expanded(
            child: _filteredInventory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredInventory.length,
                    itemBuilder: (context, index) {
                      final product = _filteredInventory[index];
                      return _InventoryCard(
                        product: product,
                        onAdjustStock: () => _showAdjustStockDialog(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(MutableProduct product) {
    final controller = TextEditingController();
    String adjustmentType = 'add'; // add or remove

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stock: ${product.stockQuantity} ${product.unit}s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Adjustment Type Toggle
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          adjustmentType = 'add';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: adjustmentType == 'add'
                            ? AppTheme.successColor
                            : Colors.transparent,
                        foregroundColor: adjustmentType == 'add'
                            ? Colors.white
                            : AppTheme.successColor,
                      ),
                      child: const Text('Add Stock'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          adjustmentType = 'remove';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: adjustmentType == 'remove'
                            ? AppTheme.errorColor
                            : Colors.transparent,
                        foregroundColor: adjustmentType == 'remove'
                            ? Colors.white
                            : AppTheme.errorColor,
                      ),
                      child: const Text('Remove Stock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity Input
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  suffixText: product.unit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Text(
                adjustmentType == 'add'
                    ? 'Stock after adjustment: ${product.stockQuantity + (int.tryParse(controller.text) ?? 0)} ${product.unit}s'
                    : 'Stock after adjustment: ${(product.stockQuantity - (int.tryParse(controller.text) ?? 0)).clamp(0, product.stockQuantity)} ${product.unit}s',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(controller.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                setState(() {
                  if (adjustmentType == 'add') {
                    product.stockQuantity += quantity;
                  } else {
                    product.stockQuantity = (product.stockQuantity - quantity)
                        .clamp(0, product.stockQuantity);
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      adjustmentType == 'add'
                          ? 'Added $quantity ${product.unit}s to stock'
                          : 'Removed $quantity ${product.unit}s from stock',
                    ),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : chipColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : chipColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final MutableProduct product;
  final VoidCallback onAdjustStock;

  const _InventoryCard({required this.product, required this.onAdjustStock});

  Color get _stockColor {
    if (product.stockQuantity == 0) return AppTheme.errorColor;
    if (product.stockQuantity <= product.lowStockThreshold)
      return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String get _stockStatus {
    if (product.stockQuantity == 0) return 'Out of Stock';
    if (product.stockQuantity <= product.lowStockThreshold) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: _stockColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _stockStatus,
                    style: TextStyle(
                      fontSize: 11,
                      color: _stockColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.stockQuantity} ${product.unit}s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _stockColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Low Stock Alert',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.lowStockThreshold} ${product.unit}s',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAdjustStock,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Adjust'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
