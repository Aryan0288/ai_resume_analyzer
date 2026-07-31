import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCS4c91zwNQaLic0j9OHgLgCy4u15QNYns',
    appId: '1:823266435101:web:5af42b40c69e364759e6f4',
    messagingSenderId: '823266435101',
    projectId: 'ai-resume-analyzer-975',
    authDomain: 'ai-resume-analyzer-975.firebaseapp.com',
    storageBucket: 'ai-resume-analyzer-975.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCS4c91zwNQaLic0j9OHgLgCy4u15QNYns',
    appId: '1:823266435101:android:5af42b40c69e364759e6f4',
    messagingSenderId: '823266435101',
    projectId: 'ai-resume-analyzer-975',
    storageBucket: 'ai-resume-analyzer-975.firebasestorage.app',
  );
}
