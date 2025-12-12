// Mobile-specific download implementation (stub)
// For Android/iOS, you would typically use path_provider + share plugin
// or save to device storage

void downloadFile(List<int> bytes, String fileName) {
  // On mobile, this would save to downloads folder or share the file
  // For now, this is a stub that does nothing
  // In a real app, you'd use:
  // - path_provider to get downloads directory
  // - File I/O to save the file
  // - share_plus to share the file
  throw UnsupportedError('File download not implemented for mobile platform');
}

void downloadPdf(List<int> bytes, String fileName) {
  // On mobile, this would save to downloads folder or share the file
  throw UnsupportedError('PDF download not implemented for mobile platform');
}
