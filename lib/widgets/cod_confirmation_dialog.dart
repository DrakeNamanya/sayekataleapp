import 'package:flutter/material.dart';
import '../models/order.dart';

/// Cash on Delivery confirmation dialog
/// Both buyer and seller must confirm within 48 hours
class CodConfirmationDialog extends StatefulWidget {
  final Order order;
  final bool isBuyer;
  final Function() onConfirm;

  const CodConfirmationDialog({
    super.key,
    required this.order,
    required this.isBuyer,
    required this.onConfirm,
  });

  @override
  State<CodConfirmationDialog> createState() => _CodConfirmationDialogState();
}

class _CodConfirmationDialogState extends State<CodConfirmationDialog> {
  bool _agreedToTerms = false;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Delivery',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Order ID', widget.order.id),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Total Amount',
                    'UGX ${widget.order.totalAmount.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    widget.isBuyer ? 'Seller' : 'Buyer',
                    widget.isBuyer
                        ? widget.order.sellerName
                        : widget.order.buyerName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirmation message
            Text(
              widget.isBuyer
                  ? 'Please confirm that you have received all items and paid the full amount in cash.'
                  : 'Please confirm that you have delivered all items and received the full payment in cash.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Warning box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Important Deadline',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Both parties must confirm within 48 hours',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Failure to confirm may result in account suspension',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRemainingTime(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Terms checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _agreedToTerms = !_agreedToTerms;
                      });
                    },
                    child: Text(
                      widget.isBuyer
                          ? 'I confirm that I have received all items in good condition and have paid the seller in cash.'
                          : 'I confirm that I have delivered all items and have received the full payment in cash from the buyer.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _confirming ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _agreedToTerms && !_confirming ? _handleConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _confirming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Confirm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRemainingTime() {
    if (widget.order.deliveredAt == null) {
      return const SizedBox.shrink();
    }

    final hoursElapsed = DateTime.now()
        .difference(widget.order.deliveredAt!)
        .inHours;
    final hoursRemaining = 48 - hoursElapsed;

    if (hoursRemaining <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'DEADLINE PASSED',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Time remaining: $hoursRemaining hours',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _confirming = true;
    });

    try {
      await widget.onConfirm();

      if (mounted) {
        Navigator.pop(context, true);

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Confirmed!'),
              ],
            ),
            content: Text(
              widget.isBuyer
                  ? 'Thank you for confirming delivery. The seller will be notified.'
                  : 'Thank you for confirming. Waiting for buyer confirmation to complete the transaction.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _confirming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Show COD confirmation dialog
Future<bool?> showCodConfirmationDialog({
  required BuildContext context,
  required Order order,
  required bool isBuyer,
  required Function() onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CodConfirmationDialog(
      order: order,
      isBuyer: isBuyer,
      onConfirm: onConfirm,
    ),
  );
}
