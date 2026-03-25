import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options are only required for web in this project.
///
/// Native platforms use `google-services.json` / `GoogleService-Info.plist`
/// and initialize with `Firebase.initializeApp()` (no Dart options).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions is for web only. '
          'Use native Firebase initialization on this platform.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    final apiKey = _requiredEnv('FIREBASE_WEB_API_KEY');
    final appId = _requiredEnv('FIREBASE_WEB_APP_ID');
    final messagingSenderId = _requiredEnv('FIREBASE_WEB_MESSAGING_SENDER_ID');
    final projectId = _requiredEnv('FIREBASE_WEB_PROJECT_ID');
    final authDomain = _requiredEnv('FIREBASE_WEB_AUTH_DOMAIN');
    final storageBucket = _requiredEnv('FIREBASE_WEB_STORAGE_BUCKET');
    final measurementId = const String.fromEnvironment(
      'FIREBASE_WEB_MEASUREMENT_ID',
      defaultValue: '',
    );

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }

  static String _requiredEnv(String key) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) {
      throw UnsupportedError(
        'Missing required --dart-define=$key for Firebase web initialization.',
      );
    }
    return value;
  }
}
