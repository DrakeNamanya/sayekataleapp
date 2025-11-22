/// Stub implementation for non-web platforms
class CsvExportServiceImpl {
  /// Export users - throws on non-web platforms
  Future<void> exportUsers() async {
    throw UnsupportedError('CSV export is only available on web platform');
  }

  /// Export products - throws on non-web platforms
  Future<void> exportProducts() async {
    throw UnsupportedError('CSV export is only available on web platform');
  }

  /// Export orders - throws on non-web platforms
  Future<void> exportOrders() async {
    throw UnsupportedError('CSV export is only available on web platform');
  }

  /// Export complaints - throws on non-web platforms
  Future<void> exportComplaints() async {
    throw UnsupportedError('CSV export is only available on web platform');
  }

  /// Export custom data - throws on non-web platforms
  Future<void> exportToCSV({
    required List<Map<String, dynamic>> data,
    required String filename,
  }) async {
    throw UnsupportedError('CSV export is only available on web platform');
  }
}
