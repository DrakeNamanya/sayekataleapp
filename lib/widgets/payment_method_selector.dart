import 'package:flutter/material.dart';
import '../models/order.dart';

/// Payment method selector widget
/// Allows users to choose between MTN MoMo, Airtel Money, and COD
class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;
  final bool showCashOnDelivery;
  final OrderType orderType;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showCashOnDelivery = true,
    required this.orderType,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // MTN Mobile Money
        _buildPaymentMethodTile(
          method: PaymentMethod.mtnMobileMoney,
          icon: Icons.phone_android,
          color: Colors.yellow.shade700,
          title: 'MTN Mobile Money',
          subtitle: 'Pay with your MTN MoMo account',
        ),
        const SizedBox(height: 12),

        // Airtel Money
        _buildPaymentMethodTile(
          method: PaymentMethod.airtelMoney,
          icon: Icons.phone_android,
          color: Colors.red,
          title: 'Airtel Money',
          subtitle: 'Pay with your Airtel Money account',
          isDisabled: true, // Coming soon
          disabledText: 'Coming Soon',
        ),
        const SizedBox(height: 12),

        // Cash on Delivery (only for SME → SHG purchases)
        if (widget.showCashOnDelivery &&
            widget.orderType == OrderType.smeToShgProductPurchase)
          _buildPaymentMethodTile(
            method: PaymentMethod.cashOnDelivery,
            icon: Icons.money,
            color: Colors.green,
            title: 'Cash on Delivery',
            subtitle: 'Pay in cash when you receive the items',
            warningText: '⚠️ Both parties must confirm within 48 hours',
          ),

        const SizedBox(height: 24),

        // Service fee notice (for SHG → PSA purchases)
        if (widget.orderType == OrderType.shgToPsaInputPurchase)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Service Fee',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• You pay: UGX 2,000 service fee\n'
                  '• PSA pays: UGX 5,000 service fee\n'
                  '• Total service fee: UGX 7,000',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required PaymentMethod method,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isDisabled = false,
    String? disabledText,
    String? warningText,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedMethod = method;
              });
              widget.onMethodSelected(method);
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade100
              : isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : isSelected
                ? color
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade300
                    : isSelected
                    ? color
                    : color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.grey.shade600
                    : isSelected
                    ? Colors.white
                    : color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDisabled
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                      if (isDisabled && disabledText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            disabledText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (warningText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      warningText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Radio indicator
            if (!isDisabled)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? color : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
