// File generated from android/app/google-services.json and ios/Runner/GoogleService-Info.plist
// for project legalai-b363d. Do not use the Firebase Admin SDK JSON in the app — that is for
// backend/Cloud Functions only. To regenerate: run `dart run flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for the current platform.
/// Values match android/app/google-services.json and ios/Runner/GoogleService-Info.plist.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCR7CsbmPXh_wCZozQHAipQO1Yx0n6bylY',
    appId: '1:1011844190364:android:8f02d1fad780d6f899dd59',
    messagingSenderId: '1011844190364',
    projectId: 'legalai-b363d',
    storageBucket: 'legalai-b363d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCVW8uty1VwWi0qAp-DCEir6WJy2nc-aCM',
    appId: '1:1011844190364:ios:1fc5854d5c65e7f799dd59',
    messagingSenderId: '1011844190364',
    projectId: 'legalai-b363d',
    storageBucket: 'legalai-b363d.firebasestorage.app',
    iosBundleId: 'com.legalai.app',
  );
}
