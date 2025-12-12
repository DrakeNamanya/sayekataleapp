// Platform-agnostic download helper
// Uses conditional exports to load platform-specific implementation

export 'download_helper_web.dart' if (dart.library.io) 'download_helper_mobile.dart';
