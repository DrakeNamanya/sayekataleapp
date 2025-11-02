// File generated for Firebase configuration
// DO NOT EDIT - Update from Firebase Console when needed

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Configuration
  // To add Web support, register web app in Firebase Console and update these values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg',
    appId: '1:713040690605:web:c6a94df85689638fcb7524',
    messagingSenderId: '713040690605',
    projectId: 'sayekataleapp',
    authDomain: 'sayekataleapp.firebaseapp.com',
    storageBucket: 'sayekataleapp.firebasestorage.app',
  );

  // Android Configuration (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg',
    appId: '1:713040690605:android:060c649529abd85ccb7524',
    messagingSenderId: '713040690605',
    projectId: 'sayekataleapp',
    storageBucket: 'sayekataleapp.firebasestorage.app',
  );

  // iOS Configuration
  // To add iOS support, register iOS app in Firebase Console and update these values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg',
    appId: '1:713040690605:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '713040690605',
    projectId: 'sayekataleapp',
    storageBucket: 'sayekataleapp.firebasestorage.app',
    iosBundleId: 'com.datacollectors.sayekatale',
  );
}
