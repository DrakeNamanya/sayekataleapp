import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppTheme.warningColor;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return AppTheme.accentColor;
      case OrderStatus.completed:
        return AppTheme.successColor;
      case OrderStatus.cancelled:
        return AppTheme.errorColor;
    }
  }
}

class PSAOrder {
  final String id;
  final String farmerName;
  final String farmerId;
  final List<OrderItem> items;
  final double totalAmount;
  OrderStatus status; // Changed to mutable for demo purposes
  final DateTime orderDate;
  DateTime? completedDate; // Changed to mutable
  final String? notes;

  PSAOrder({
    required this.id,
    required this.farmerName,
    required this.farmerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.completedDate,
    this.notes,
  });
}

class OrderItem {
  final String productName;
  final int quantity;
  final String unit;
  final double pricePerUnit;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
  });

  double get total => quantity * pricePerUnit;
}

class PSAOrdersScreen extends StatefulWidget {
  const PSAOrdersScreen({super.key});

  @override
  State<PSAOrdersScreen> createState() => _PSAOrdersScreenState();
}

class _PSAOrdersScreenState extends State<PSAOrdersScreen> {
  OrderStatus? _filterStatus;

  // Mock orders data (in production, fetch from API/database)
  final List<PSAOrder> _orders = [
    PSAOrder(
      id: 'ORD-001',
      farmerName: 'Sarah Nakato',
      farmerId: 'SHG-00123',
      items: [
        OrderItem(
          productName: 'Hybrid Maize Seeds',
          quantity: 5,
          unit: 'bag',
          pricePerUnit: 45000,
        ),
        OrderItem(
          productName: 'NPK Fertilizer',
          quantity: 10,
          unit: 'bag',
          pricePerUnit: 120000,
        ),
      ],
      totalAmount: 1425000,
      status: OrderStatus.pending,
      orderDate: DateTime.now().subtract(const Duration(hours: 2)),
      notes: 'Urgent: Need for planting season',
    ),
    PSAOrder(
      id: 'ORD-002',
      farmerName: 'John Okello',
      farmerId: 'SHG-00124',
      items: [
        OrderItem(
          productName: 'Day-Old Chicks',
          quantity: 100,
          unit: 'piece',
          pricePerUnit: 3500,
        ),
        OrderItem(
          productName: 'Starter Feed',
          quantity: 4,
          unit: 'bag',
          pricePerUnit: 85000,
        ),
      ],
      totalAmount: 690000,
      status: OrderStatus.confirmed,
      orderDate: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PSAOrder(
      id: 'ORD-003',
      farmerName: 'Mary Auma',
      farmerId: 'SHG-00125',
      items: [
        OrderItem(
          productName: 'Hand Hoe',
          quantity: 3,
          unit: 'piece',
          pricePerUnit: 15000,
        ),
      ],
      totalAmount: 45000,
      status: OrderStatus.ready,
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PSAOrder(
      id: 'ORD-004',
      farmerName: 'James Musoke',
      farmerId: 'SHG-00126',
      items: [
        OrderItem(
          productName: 'Pesticide Spray',
          quantity: 5,
          unit: 'liter',
          pricePerUnit: 35000,
        ),
      ],
      totalAmount: 175000,
      status: OrderStatus.completed,
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      completedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<PSAOrder> get _filteredOrders {
    if (_filterStatus == null) {
      return _orders;
    }
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  int _getStatusCount(OrderStatus status) {
    return _orders.where((order) => order.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Input Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Summary
          Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatusCard(
                  status: OrderStatus.pending,
                  count: _getStatusCount(OrderStatus.pending),
                  isSelected: _filterStatus == OrderStatus.pending,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == OrderStatus.pending ? null : OrderStatus.pending;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _StatusCard(
                  status: OrderStatus.confirmed,
                  count: _getStatusCount(OrderStatus.confirmed),
                  isSelected: _filterStatus == OrderStatus.confirmed,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == OrderStatus.confirmed ? null : OrderStatus.confirmed;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _StatusCard(
                  status: OrderStatus.ready,
                  count: _getStatusCount(OrderStatus.ready),
                  isSelected: _filterStatus == OrderStatus.ready,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == OrderStatus.ready ? null : OrderStatus.ready;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _StatusCard(
                  status: OrderStatus.completed,
                  count: _getStatusCount(OrderStatus.completed),
                  isSelected: _filterStatus == OrderStatus.completed,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == OrderStatus.completed ? null : OrderStatus.completed;
                    });
                  },
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: _filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
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
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _OrderCard(
                        order: order,
                        onTap: () => _showOrderDetails(order),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            return RadioListTile<OrderStatus?>(
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(status.displayName),
                  const Spacer(),
                  Text(
                    '(${_getStatusCount(status)})',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              value: status,
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() {
                  _filterStatus = value;
                });
                Navigator.pop(context);
              },
            );
          }).toList()
            ..insert(
              0,
              RadioListTile<OrderStatus?>(
                title: Row(
                  children: [
                    const Text('All Orders'),
                    const Spacer(),
                    Text(
                      '(${_orders.length})',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                value: null,
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(PSAOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.farmerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: order.status.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Order Items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} ${item.unit}s × UGX ${item.pricePerUnit.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'UGX ${item.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 16),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'UGX ${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (order.notes != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Order Info
                    _InfoRow(
                      label: 'Order Date',
                      value: '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year} ${order.orderDate.hour}:${order.orderDate.minute.toString().padLeft(2, '0')}',
                    ),
                    _InfoRow(
                      label: 'Farmer ID',
                      value: order.farmerId,
                    ),
                    if (order.completedDate != null)
                      _InfoRow(
                        label: 'Completed Date',
                        value: '${order.completedDate!.day}/${order.completedDate!.month}/${order.completedDate!.year}',
                      ),
                  ],
                ),
              ),

              // Action Buttons
              const SizedBox(height: 16),
              if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled)
                Row(
                  children: [
                    if (order.status == OrderStatus.pending)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              order.status = OrderStatus.confirmed;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order confirmed!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          child: const Text('Confirm Order'),
                        ),
                      ),
                    if (order.status == OrderStatus.confirmed)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              order.status = OrderStatus.ready;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order marked as ready!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          child: const Text('Mark as Ready'),
                        ),
                      ),
                    if (order.status == OrderStatus.ready)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              order.status = OrderStatus.completed;
                              order.completedDate = DateTime.now();
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order completed!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          child: const Text('Complete Order'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final OrderStatus status;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusCard({
    required this.status,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? status.color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: status.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : status.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PSAOrder order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.farmerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: order.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: order.status.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
                          'Items',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${order.items.length} products',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                          'Total',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'UGX ${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
