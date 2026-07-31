import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';

/// Central wrapper managing Firebase initializations and resource clients.
class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Gracefully handle re-initialization in hot restart environments
    }
  }

  // Live Firebase service client accessors
  FirebaseAuth? get auth => FirebaseAuth.instance;
  FirebaseFirestore? get firestore => FirebaseFirestore.instance;
  FirebaseFunctions? get functions => FirebaseFunctions.instance;
  FirebaseStorage? get storage => FirebaseStorage.instance;
}
