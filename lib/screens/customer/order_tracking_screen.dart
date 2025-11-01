import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock order data
    final mockOrder = Order(
      id: '1001',
      customerId: 'customer1',
      farmId: 'farm1',
      items: [
        OrderItem(
          productId: 'prod1',
          productName: 'Fresh Chicken Eggs',
          quantity: 2,
          unitPrice: 12000,
          total: 24000,
        ),
      ],
      subtotal: 24000,
      deliveryFee: 5000,
      serviceFee: 1200,
      total: 30200,
      paymentMethod: PaymentMethod.mtnMomo,
      paymentStatus: PaymentStatus.completed,
      statusTimeline: [
        OrderStatusTimeline(
          status: OrderStatus.placed,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.accepted,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.preparing,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.outForDelivery,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
      estimatedDelivery: '15-20 minutes',
      riderName: 'James Okello',
      riderPhone: '+256 700 123 789',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Status Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppTheme.primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mockOrder.currentStatus.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimated delivery: ${mockOrder.estimatedDelivery}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Order Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Order #${mockOrder.id}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ...mockOrder.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.productName}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Text(
                                  'UGX ${item.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 16),
                      _OrderPriceRow('Subtotal', mockOrder.subtotal),
                      _OrderPriceRow('Delivery Fee', mockOrder.deliveryFee),
                      _OrderPriceRow('Service Fee', mockOrder.serviceFee),
                      const Divider(height: 16),
                      _OrderPriceRow('Total', mockOrder.total, isBold: true),
                    ],
                  ),
                ),
              ),
              // Delivery Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Delivery Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DeliveryTimeline(timeline: mockOrder.statusTimeline),
              // Rider Contact
              if (mockOrder.riderName != null)
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      mockOrder.riderName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Delivery Rider'),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                      onPressed: () {
                        // Call rider
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _OrderPriceRow(this.label, this.amount, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            'UGX ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTimeline extends StatelessWidget {
  final List<OrderStatusTimeline> timeline;

  const _DeliveryTimeline({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: timeline.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == timeline.length - 1;
          final isCompleted = true; // All items in timeline are completed

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.successColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 50,
                      color: isCompleted ? AppTheme.successColor : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.status.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(item.timestamp),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
