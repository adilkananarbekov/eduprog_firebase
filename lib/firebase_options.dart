import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options generated manually from the provided web app config.
///
/// Only web credentials were provided, so non-web platforms must be configured
/// later with their own FlutterFire app registrations.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'Firebase is configured only for web in this project. '
      'Add platform-specific Firebase apps before running on '
      '${defaultTargetPlatform.name}.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCm-wtRI2Q5sUndOH2tZP__dkA4kL8id58',
    appId: '1:796694555251:web:a609003dc00df9f3f2d806',
    messagingSenderId: '796694555251',
    projectId: 'eduops-25a60',
    authDomain: 'eduops-25a60.firebaseapp.com',
    storageBucket: 'eduops-25a60.firebasestorage.app',
    measurementId: 'G-CD2D0T9X8S',
  );
}
