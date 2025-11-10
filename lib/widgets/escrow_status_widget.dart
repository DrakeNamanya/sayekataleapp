import 'package:flutter/material.dart';
import '../models/order.dart' as app_order;
import '../models/order_extensions.dart';
import '../models/transaction.dart' as app_transaction;

/// Escrow status widget showing payment status and next steps
class EscrowStatusWidget extends StatelessWidget {
  final app_order.Order order;
  final app_transaction.Transaction? transaction;
  final bool isBuyer;

  const EscrowStatusWidget({
    super.key,
    required this.order,
    this.transaction,
    required this.isBuyer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.1),
            _getStatusColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _getStatusColor(), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getStatusIcon(), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusSubtitle(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 20),

          // Status details
          _buildStatusDetails(context),

          // Action button
          if (_shouldShowActionButton())
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildActionButton(context),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // STATUS INFORMATION
  // ============================================================================

  Color _getStatusColor() {
    switch (order.status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return Colors.orange;
      case app_order.OrderStatus.paymentHeld:
      case app_order.OrderStatus.deliveryPending:
        return Colors.blue;
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return Colors.purple;
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.completed:
        return Colors.green;
      case app_order.OrderStatus.cancelled:
      case app_order.OrderStatus.codOverdue:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (order.status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return Icons.hourglass_empty;
      case app_order.OrderStatus.paymentHeld:
        return Icons.lock;
      case app_order.OrderStatus.deliveryPending:
        return Icons.local_shipping;
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return Icons.check_circle_outline;
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.completed:
        return Icons.check_circle;
      case app_order.OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle() {
    switch (order.status) {
      case app_order.OrderStatus.pending:
        return 'Payment Required';
      case app_order.OrderStatus.paymentPending:
        return 'Processing Payment';
      case app_order.OrderStatus.paymentHeld:
        return 'Payment Secured';
      case app_order.OrderStatus.deliveryPending:
        return isBuyer ? 'Awaiting Delivery' : 'Ready to Deliver';
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return isBuyer ? 'Confirm Receipt' : 'Awaiting Confirmation';
      case app_order.OrderStatus.confirmed:
        return 'Delivery Confirmed';
      case app_order.OrderStatus.completed:
        return 'app_order.Order Completed';
      case app_order.OrderStatus.cancelled:
        return 'app_order.Order Cancelled';
      default:
        return 'app_order.Order Status';
    }
  }

  String _getStatusSubtitle() {
    if (order.paymentMethod == app_order.PaymentMethod.cashOnDelivery) {
      switch (order.status) {
        case app_order.OrderStatus.pending:
          return 'Cash on Delivery order placed';
        case app_order.OrderStatus.deliveryPending:
          return isBuyer ? 'Seller is preparing your order' : 'Deliver items to buyer';
        case app_order.OrderStatus.deliveredPendingConfirmation:
          if (isBuyer) {
            return 'Confirm you received the items';
          } else {
            return 'Waiting for buyer to confirm receipt';
          }
        case app_order.OrderStatus.confirmed:
          return 'Both parties confirmed the transaction';
        case app_order.OrderStatus.completed:
          return 'app_transaction.Transaction successfully completed';
        default:
          return '';
      }
    }

    // Mobile Money orders
    switch (order.status) {
      case app_order.OrderStatus.pending:
        return 'Complete payment to proceed';
      case app_order.OrderStatus.paymentPending:
        return 'Confirming your payment...';
      case app_order.OrderStatus.paymentHeld:
        return 'Your payment is held safely in escrow';
      case app_order.OrderStatus.deliveryPending:
        return isBuyer ? 'Seller will deliver your items soon' : 'Deliver items to buyer';
      case app_order.OrderStatus.deliveredPendingConfirmation:
        if (isBuyer) {
          return 'Confirm you received the items to release payment';
        } else {
          return 'Waiting for buyer confirmation to receive payment';
        }
      case app_order.OrderStatus.confirmed:
        return 'Payment released to seller';
      case app_order.OrderStatus.completed:
        return 'app_transaction.Transaction successfully completed';
      case app_order.OrderStatus.cancelled:
        return order.cancellationReason ?? 'app_order.Order was cancelled';
      default:
        return '';
    }
  }

  // ============================================================================
  // PROGRESS INDICATOR
  // ============================================================================

  Widget _buildProgressIndicator() {
    int currentStep = _getCurrentStep();
    int totalSteps = order.paymentMethod == app_order.PaymentMethod.cashOnDelivery ? 3 : 4;

    return Row(
      children: List.generate(
        totalSteps,
        (index) => Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < currentStep
                        ? _getStatusColor()
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < totalSteps - 1) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  int _getCurrentStep() {
    if (order.paymentMethod == app_order.PaymentMethod.cashOnDelivery) {
      switch (order.status) {
        case app_order.OrderStatus.pending:
        case app_order.OrderStatus.paymentPending:
          return 0;
        case app_order.OrderStatus.deliveryPending:
          return 1;
        case app_order.OrderStatus.deliveredPendingConfirmation:
          return 2;
        case app_order.OrderStatus.confirmed:
        case app_order.OrderStatus.completed:
          return 3;
        default:
          return 0;
      }
    }

    // Mobile Money
    switch (order.status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return 0;
      case app_order.OrderStatus.paymentHeld:
        return 1;
      case app_order.OrderStatus.deliveryPending:
        return 2;
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return 3;
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.completed:
        return 4;
      default:
        return 0;
    }
  }

  // ============================================================================
  // STATUS DETAILS
  // ============================================================================

  Widget _buildStatusDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('app_order.Order ID', order.id),
          const Divider(height: 24),
          _buildDetailRow('Total Amount', 'UGX ${order.totalAmount.toStringAsFixed(0)}'),
          if (order.serviceFee > 0) ...[
            const Divider(height: 24),
            _buildDetailRow('Service Fee', 'UGX ${order.serviceFee.toStringAsFixed(0)}'),
          ],
          const Divider(height: 24),
          _buildDetailRow('Payment Method', order.paymentMethod.displayName),
          if (order.paymentMethod == app_order.PaymentMethod.cashOnDelivery &&
              order.status == app_order.OrderStatus.deliveredPendingConfirmation) ...[
            const Divider(height: 24),
            _buildCodDeadlineWarning(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCodDeadlineWarning() {
    if (order.deliveredAt == null) return const SizedBox.shrink();

    final hoursElapsed = DateTime.now().difference(order.deliveredAt!).inHours;
    final hoursRemaining = 48 - hoursElapsed;

    if (hoursRemaining <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '48-hour confirmation deadline passed!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Confirm within $hoursRemaining hours or account will be flagged',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ACTION BUTTON
  // ============================================================================

  bool _shouldShowActionButton() {
    if (isBuyer) {
      return order.status == app_order.OrderStatus.deliveredPendingConfirmation;
    } else {
      return order.status == app_order.OrderStatus.deliveryPending ||
          order.status == app_order.OrderStatus.deliveredPendingConfirmation;
    }
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText;
    VoidCallback? onPressed;

    if (isBuyer && order.status == app_order.OrderStatus.deliveredPendingConfirmation) {
      buttonText = 'Confirm Receipt';
      onPressed = () {
        // TODO: Implement confirmation
      };
    } else if (!isBuyer && order.status == app_order.OrderStatus.deliveryPending) {
      buttonText = 'Mark as Delivered';
      onPressed = () {
        // TODO: Implement marking as delivered
      };
    } else {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getStatusColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
