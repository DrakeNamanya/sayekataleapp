// Conditional import based on platform
import 'csv_export_service_stub.dart'
    if (dart.library.html) 'csv_export_service_web.dart';

/// Service for exporting Firestore data to CSV files
/// Uses conditional imports to support both web and mobile platforms
/// Web platform: Full CSV export functionality
/// Mobile platforms: Throws UnsupportedError
class CsvExportService {
  final CsvExportServiceImpl _impl = CsvExportServiceImpl();

  /// Export users collection to CSV
  Future<void> exportUsers() => _impl.exportUsers();

  /// Export products collection to CSV
  Future<void> exportProducts() => _impl.exportProducts();

  /// Export orders collection to CSV
  Future<void> exportOrders() => _impl.exportOrders();

  /// Export complaints collection to CSV
  Future<void> exportComplaints() => _impl.exportComplaints();
}
