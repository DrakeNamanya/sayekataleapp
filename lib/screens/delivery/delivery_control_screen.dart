import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_tracking.dart';
import '../../services/delivery_tracking_service.dart';
import '../../providers/auth_provider.dart';
import 'live_tracking_screen.dart';
import 'package:intl/intl.dart';

/// Delivery control screen for delivery persons (SHG farmers and PSA suppliers)
/// Allows starting, updating, completing, and cancelling deliveries
class DeliveryControlScreen extends StatefulWidget {
  const DeliveryControlScreen({super.key});

  @override
  State<DeliveryControlScreen> createState() => _DeliveryControlScreenState();
}

class _DeliveryControlScreenState extends State<DeliveryControlScreen>
    with SingleTickerProviderStateMixin {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  late TabController _tabController;

  List<DeliveryTracking> _activeDeliveries = [];
  List<DeliveryTracking> _completedDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeliveries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackingService.dispose();
    super.dispose();
  }

  /// Load deliveries for current user
  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final allDeliveries = await _trackingService.getActiveDeliveriesForPerson(
        userId,
      );

      setState(() {
        _activeDeliveries = allDeliveries
            .where(
              (d) =>
                  d.status == DeliveryStatus.pending ||
                  d.status == DeliveryStatus.confirmed ||
                  d.status == DeliveryStatus.inProgress,
            )
            .toList();

        _completedDeliveries = allDeliveries
            .where(
              (d) =>
                  d.status == DeliveryStatus.completed ||
                  d.status == DeliveryStatus.cancelled ||
                  d.status == DeliveryStatus.failed,
            )
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading deliveries: $e')));
      }
    }
  }

  /// Start delivery
  Future<void> _startDelivery(DeliveryTracking tracking) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start Delivery'),
          content: Text(
            'Start delivery to ${tracking.recipientName}?\n\n'
            'GPS tracking will begin and the recipient will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start Delivery'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Start delivery
      await _trackingService.startDelivery(tracking.id);

      // Start continuous location tracking
      await _trackingService.startLocationTracking(tracking.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery started! GPS tracking is active.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload deliveries
      await _loadDeliveries();

      // Navigate to live tracking screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveTrackingScreen(trackingId: tracking.id),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Complete delivery
  Future<void> _completeDelivery(DeliveryTracking tracking) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete Delivery'),
          content: const Text(
            'Mark this delivery as completed?\n\n'
            'GPS tracking will stop and the recipient will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Complete delivery
      await _trackingService.completeDelivery(tracking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload deliveries
      await _loadDeliveries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cancel delivery
  Future<void> _cancelDelivery(DeliveryTracking tracking) async {
    try {
      // Show reason input dialog
      final TextEditingController reasonController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for cancellation:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g., Customer unavailable, vehicle breakdown',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Delivery'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide a cancellation reason'),
            ),
          );
        }
        return;
      }

      // Cancel delivery
      await _trackingService.cancelDelivery(tracking.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Reload deliveries
      await _loadDeliveries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to live tracking screen
  void _viewLiveTracking(DeliveryTracking tracking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(trackingId: tracking.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (_activeDeliveries.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activeDeliveries.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Active Deliveries Tab
                _activeDeliveries.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.local_shipping,
                        title: 'No Active Deliveries',
                        message: 'You have no active deliveries at the moment.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDeliveries,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeDeliveries.length,
                          itemBuilder: (context, index) {
                            return _buildDeliveryCard(
                              _activeDeliveries[index],
                              isActive: true,
                            );
                          },
                        ),
                      ),

                // Completed Deliveries Tab
                _completedDeliveries.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.history,
                        title: 'No Delivery History',
                        message: 'Your completed deliveries will appear here.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDeliveries,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _completedDeliveries.length,
                          itemBuilder: (context, index) {
                            return _buildDeliveryCard(
                              _completedDeliveries[index],
                              isActive: false,
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(
    DeliveryTracking tracking, {
    required bool isActive,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (tracking.status) {
      case DeliveryStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case DeliveryStatus.confirmed:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case DeliveryStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.local_shipping;
        break;
      case DeliveryStatus.completed:
        statusColor = Colors.teal;
        statusIcon = Icons.done_all;
        break;
      case DeliveryStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case DeliveryStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewLiveTracking(tracking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${tracking.orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tracking.deliveryType == 'SHG_TO_SME'
                              ? 'Delivery to SME Buyer'
                              : 'Delivery from PSA Supplier',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          tracking.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Recipient info
              Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipient',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          tracking.recipientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Distance and duration
              Row(
                children: [
                  if (tracking.estimatedDistance != null)
                    _buildInfoItem(
                      icon: Icons.route,
                      label:
                          '${tracking.estimatedDistance!.toStringAsFixed(1)} km',
                    ),
                  if (tracking.estimatedDuration != null) ...[
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      icon: Icons.timer,
                      label: '${tracking.estimatedDuration} min',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(tracking.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Action buttons for active deliveries
              if (isActive) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (tracking.status == DeliveryStatus.pending ||
                        tracking.status == DeliveryStatus.confirmed)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startDelivery(tracking),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start Delivery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (tracking.status == DeliveryStatus.inProgress) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _viewLiveTracking(tracking),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('View Map'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completeDelivery(tracking),
                          icon: const Icon(Icons.done, size: 18),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                    if (tracking.status != DeliveryStatus.completed) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _cancelDelivery(tracking),
                        icon: const Icon(Icons.close),
                        color: Colors.red,
                        tooltip: 'Cancel',
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
