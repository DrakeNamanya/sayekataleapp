import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../models/delivery_tracking.dart';
import '../../services/delivery_tracking_service.dart';
import 'package:intl/intl.dart';

/// Live tracking map screen for monitoring real-time delivery progress
/// Shows delivery person's location, route, ETA, and contact options
class LiveTrackingScreen extends StatefulWidget {
  final String trackingId;

  const LiveTrackingScreen({
    super.key,
    required this.trackingId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  GoogleMapController? _mapController;
  StreamSubscription<DeliveryTracking?>? _trackingSubscription;
  
  DeliveryTracking? _currentTracking;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _startTrackingStream();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Start listening to real-time tracking updates
  void _startTrackingStream() {
    _trackingSubscription = _trackingService
        .streamDeliveryTracking(widget.trackingId)
        .listen((tracking) {
      if (tracking != null && mounted) {
        setState(() {
          _currentTracking = tracking;
          _updateMapElements(tracking);
        });

        // Auto-center map on first update
        if (_isMapReady && _mapController != null) {
          _fitMapToRoute(tracking);
        }
      }
    });
  }

  /// Update markers and polylines based on current tracking data
  void _updateMapElements(DeliveryTracking tracking) {
    _markers.clear();
    _polylines.clear();

    // Origin marker (green pin)
    _markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(
        tracking.originLocation.latitude,
        tracking.originLocation.longitude,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Starting Point',
        snippet: tracking.originLocation.address ?? 'Origin',
      ),
    ));

    // Destination marker (red pin)
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: LatLng(
        tracking.destinationLocation.latitude,
        tracking.destinationLocation.longitude,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Destination',
        snippet: tracking.destinationLocation.address ?? 'Destination',
      ),
    ));

    // Current location marker (blue pin) - only if delivery is in progress
    if (tracking.currentLocation != null && tracking.isInProgress) {
      _markers.add(Marker(
        markerId: const MarkerId('current'),
        position: LatLng(
          tracking.currentLocation!.latitude,
          tracking.currentLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: '${tracking.deliveryPersonName} (Delivery Person)',
          snippet: 'Current location',
        ),
        rotation: 0.0,
      ));

      // Draw polyline route
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(
            tracking.originLocation.latitude,
            tracking.originLocation.longitude,
          ),
          if (tracking.locationHistory.isNotEmpty)
            ...tracking.locationHistory.map((loc) => LatLng(loc.latitude, loc.longitude)),
          LatLng(
            tracking.currentLocation!.latitude,
            tracking.currentLocation!.longitude,
          ),
          LatLng(
            tracking.destinationLocation.latitude,
            tracking.destinationLocation.longitude,
          ),
        ],
        color: Colors.blue,
        width: 4,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      ));
    }
  }

  /// Fit map camera to show entire route
  void _fitMapToRoute(DeliveryTracking tracking) {
    if (_mapController == null) return;

    final bounds = _calculateBounds(tracking);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// Calculate bounds to fit all markers
  LatLngBounds _calculateBounds(DeliveryTracking tracking) {
    double minLat = tracking.originLocation.latitude;
    double maxLat = tracking.originLocation.latitude;
    double minLng = tracking.originLocation.longitude;
    double maxLng = tracking.originLocation.longitude;

    void updateBounds(double lat, double lng) {
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    updateBounds(tracking.destinationLocation.latitude, tracking.destinationLocation.longitude);
    if (tracking.currentLocation != null) {
      updateBounds(tracking.currentLocation!.latitude, tracking.currentLocation!.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Launch phone call to delivery person
  Future<void> _callDeliveryPerson() async {
    if (_currentTracking == null) return;
    
    final phone = _currentTracking!.deliveryPersonPhone;
    final uri = Uri.parse('tel:$phone');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make phone call')),
        );
      }
    }
  }

  /// Launch SMS to delivery person
  Future<void> _messageDeliveryPerson() async {
    if (_currentTracking == null) return;
    
    final phone = _currentTracking!.deliveryPersonPhone;
    final uri = Uri.parse('sms:$phone');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send SMS')),
        );
      }
    }
  }

  /// Center map on current location
  void _centerOnCurrentLocation() {
    if (_currentTracking?.currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            _currentTracking!.currentLocation!.latitude,
            _currentTracking!.currentLocation!.longitude,
          ),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTracking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Tracking'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final tracking = _currentTracking!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startTrackingStream,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          _buildStatusBanner(tracking),

          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      tracking.originLocation.latitude,
                      tracking.originLocation.longitude,
                    ),
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _isMapReady = true;
                    _fitMapToRoute(tracking);
                  },
                ),

                // Center on location button
                if (tracking.isInProgress && tracking.currentLocation != null)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: FloatingActionButton.small(
                      onPressed: _centerOnCurrentLocation,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),

          // Delivery Details
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(tracking),
                  const SizedBox(height: 16),
                  _buildDeliveryPersonCard(tracking),
                  const SizedBox(height: 16),
                  _buildLocationDetailsCard(tracking),
                  const SizedBox(height: 16),
                  _buildStatusTimeline(tracking),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Status banner at top
  Widget _buildStatusBanner(DeliveryTracking tracking) {
    Color bgColor;
    IconData icon;
    String statusText;

    switch (tracking.status) {
      case DeliveryStatus.pending:
        bgColor = Colors.orange.shade100;
        icon = Icons.pending;
        statusText = 'Delivery Not Started';
        break;
      case DeliveryStatus.confirmed:
        bgColor = Colors.blue.shade100;
        icon = Icons.check_circle;
        statusText = 'Delivery Confirmed';
        break;
      case DeliveryStatus.inProgress:
        bgColor = Colors.green.shade100;
        icon = Icons.local_shipping;
        statusText = 'Delivery In Progress';
        break;
      case DeliveryStatus.completed:
        bgColor = Colors.teal.shade100;
        icon = Icons.done_all;
        statusText = 'Delivery Completed';
        break;
      case DeliveryStatus.cancelled:
        bgColor = Colors.red.shade100;
        icon = Icons.cancel;
        statusText = 'Delivery Cancelled';
        break;
      case DeliveryStatus.failed:
        bgColor = Colors.red.shade100;
        icon = Icons.error;
        statusText = 'Delivery Failed';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (tracking.isInProgress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Progress card with distance and ETA
  Widget _buildProgressCard(DeliveryTracking tracking) {
    final progress = tracking.progressPercentage;
    final eta = tracking.estimatedArrival;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (tracking.estimatedDistance != null)
                  _buildInfoChip(
                    icon: Icons.route,
                    label: '${tracking.estimatedDistance!.toStringAsFixed(1)} km',
                  ),
                if (tracking.estimatedDuration != null)
                  _buildInfoChip(
                    icon: Icons.timer,
                    label: '${tracking.estimatedDuration} min',
                  ),
                if (eta != null && tracking.isInProgress)
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: 'ETA ${DateFormat.jm().format(eta)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Delivery person contact card
  Widget _buildDeliveryPersonCard(DeliveryTracking tracking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Person',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    tracking.deliveryPersonName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking.deliveryPersonName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tracking.deliveryPersonPhone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _callDeliveryPerson,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _messageDeliveryPerson,
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Location details card
  Widget _buildLocationDetailsCard(DeliveryTracking tracking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Locations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationRow(
              icon: Icons.location_on,
              color: Colors.green,
              label: 'From',
              address: tracking.originLocation.address ?? 
                       '${tracking.originLocation.latitude.toStringAsFixed(6)}, ${tracking.originLocation.longitude.toStringAsFixed(6)}',
            ),
            const Divider(height: 24),
            _buildLocationRow(
              icon: Icons.flag,
              color: Colors.red,
              label: 'To',
              address: tracking.destinationLocation.address ?? 
                       '${tracking.destinationLocation.latitude.toStringAsFixed(6)}, ${tracking.destinationLocation.longitude.toStringAsFixed(6)}',
            ),
            if (tracking.notes != null && tracking.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tracking.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Status timeline
  Widget _buildStatusTimeline(DeliveryTracking tracking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Timeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.check_circle,
              title: 'Order Created',
              time: DateFormat('MMM dd, yyyy • hh:mm a').format(tracking.createdAt),
              isCompleted: true,
            ),
            if (tracking.startedAt != null)
              _buildTimelineItem(
                icon: Icons.local_shipping,
                title: 'Delivery Started',
                time: DateFormat('MMM dd, yyyy • hh:mm a').format(tracking.startedAt!),
                isCompleted: true,
              ),
            if (tracking.completedAt != null)
              _buildTimelineItem(
                icon: Icons.done_all,
                title: 'Delivery Completed',
                time: DateFormat('MMM dd, yyyy • hh:mm a').format(tracking.completedAt!),
                isCompleted: true,
                isLast: true,
              )
            else
              _buildTimelineItem(
                icon: Icons.pending,
                title: tracking.isInProgress ? 'In Progress' : 'Pending',
                time: tracking.isInProgress ? 'Ongoing' : 'Not started',
                isCompleted: false,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String time,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.blue : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.blue : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
