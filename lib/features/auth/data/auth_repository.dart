import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;

  AuthRepository([this._firebaseAuth]) {
    if (kIsWeb) {
      final auth = _firebaseAuth ?? FirebaseAuth.instance;
      auth.getRedirectResult().then((credential) {
        if (credential.user != null) {
          debugPrint('Redirect Auth succeeded for user: ${credential.user?.email}');
        }
      }).catchError((e) {
        debugPrint('Redirect Auth error: $e');
      });
    }
  }

  Stream<AuthUser?> get onAuthStateChanged {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    return auth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    });
  }

  Future<AuthUser?> signInWithEmail(String email, String password) async {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    final UserCredential credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    }
    return null;
  }

  Future<AuthUser?> registerWithEmail(String email, String password) async {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    final UserCredential credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    }
    return null;
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    await auth.signOut();
  }

  Future<AuthUser?> signInAnonymously() async {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    final UserCredential credential = await auth.signInAnonymously();
    final user = credential.user;
    if (user != null) {
      return AuthUser(
        uid: user.uid,
        email: user.email ?? 'anonymous@resumatch.ai',
        displayName: 'Guest User',
      );
    }
    return null;
  }



  Future<AuthUser?> signInWithGoogle() async {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      try {
        final UserCredential credential = await auth.signInWithPopup(googleProvider);
        final user = credential.user;
        if (user != null) {
          return AuthUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? (user.email?.split('@').first ?? 'Google User'),
            photoUrl: user.photoURL,
          );
        }
      } catch (e) {
        debugPrint('signInWithPopup failed/closed ($e). Retrying with signInWithRedirect...');
        try {
          await auth.signInWithRedirect(googleProvider);
        } catch (redirectError) {
          debugPrint('signInWithRedirect error: $redirectError');
        }
        return null;
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          return AuthUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? googleUser.displayName ?? 'Google User',
            photoUrl: user.photoURL ?? googleUser.photoUrl,
          );
        }
      }
    }
    return null;
  }

  Future<AuthUser?> updateUserProfile(String displayName) async {
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      final updatedUser = auth.currentUser;
      return AuthUser(
        uid: updatedUser?.uid ?? user.uid,
        email: updatedUser?.email ?? user.email ?? '',
        displayName: updatedUser?.displayName ?? displayName,
        photoUrl: updatedUser?.photoURL ?? user.photoURL,
      );
    }
    return null;
  }
}
