import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Web client ID from Firebase (Project settings → Your apps → Web app).
/// Required on Android so Google returns an ID token Firebase Auth accepts.
const String _kFirebaseGoogleWebClientId =
    '212715503122-j2di6qp94erapbiqieu0dohn0qrgasla.apps.googleusercontent.com';

/// Maps [PlatformException] from `google_sign_in` to a clear, actionable message.
String _googleSignInPlatformMessage(PlatformException e) {
  final code = e.code;
  final details = e.message ?? '';
  // ApiException:10 = DEVELOPER_ERROR (wrong/missing SHA-1 in Firebase / OAuth client)
  if (code == 'sign_in_failed' &&
      (details.contains('10:') || details.contains('DEVELOPER_ERROR'))) {
    return 'Google Sign-In failed (Android setup). Add the SHA-1 fingerprint of '
        'the keystore that signed this APK to Firebase Console → Project settings '
        '→ Your Android app. If the app is from Google Play, use the App signing '
        'certificate fingerprint from Play Console, not only the upload key. '
        'Then download google-services.json again and rebuild.';
  }
  if (code == 'network_error' || details.contains('NETWORK_ERROR')) {
    return 'Google Sign-In failed due to a network error. Check your connection '
        'and try again.';
  }
  return 'Google Sign-In failed ($code). ${details.isNotEmpty ? details : ''} '
      'If this only happens on the installed app (not in the browser), register '
      'your release keystore SHA-1 in Firebase and rebuild.';
}

/// Service handling user authentication with Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// One [GoogleSignIn] per [AuthService]. Creating a new instance for each call
  /// can leave sign-out and sign-in out of sync with the native session.
  GoogleSignIn? _googleSignInInstance;

  /// Same options for sign-in and sign-out so sessions clear correctly.
  GoogleSignIn _googleSignIn() {
    _googleSignInInstance ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _kFirebaseGoogleWebClientId,
    );
    return _googleSignInInstance!;
  }

  /// Register a new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty) throw Exception('Name is required');
    if (email.trim().isEmpty) throw Exception('Email is required');
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Create user in Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final uid = credential.user!.uid;

    // Update display name
    await credential.user!.updateDisplayName(name.trim());

    // Store user profile in Firestore
    final user = UserModel(
      id: uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());

    return user;
  }

  /// Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) throw Exception('Email is required');
    if (password.isEmpty) throw Exception('Password is required');

    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final uid = credential.user!.uid;

    // Fetch user profile from Firestore
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }

    // Fallback: create profile from auth data
    return UserModel(
      id: uid,
      name: credential.user!.displayName ?? 'User',
      email: credential.user!.email ?? email,
    );
  }

  /// Get user by ID (for session restoration)
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Android / iOS: obtain a Firebase session via Google ID token.
  Future<UserCredential> _signInWithGoogleMobile() async {
    final GoogleSignIn googleSignIn = _googleSignIn();

    // Always start from a clean Google session so stale tokens don't accumulate.
    try { await googleSignIn.signOut(); } catch (_) {}

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      throw Exception(_googleSignInPlatformMessage(e));
    }

    if (googleUser == null) {
      throw Exception('Google sign in was cancelled');
    }

    GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } on PlatformException catch (e) {
      throw Exception(_googleSignInPlatformMessage(e));
    }

    if (googleAuth.idToken == null) {
      throw Exception(
        'Google did not return an ID token. On Android, add your app\'s '
        'SHA-1 fingerprint in Firebase Console → Project settings → Your apps, '
        'then download the updated google-services.json and rebuild.',
      );
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final UserCredential userCredential;

      if (kIsWeb) {
        // Web: Use Firebase popup
        userCredential = await _auth.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        userCredential = await _signInWithGoogleMobile();
      }

      final uid = userCredential.user!.uid;

      // Check if user profile already exists in Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }

      // First time Google sign-in: create Firestore profile
      final user = UserModel(
        id: uid,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email ?? '',
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's profile picture URL in Firestore
  Future<void> updateProfilePicUrl(String userId, String url) async {
    await _firestore.collection('users').doc(userId).update({
      'profilePicUrl': url,
    });
  }

  /// Update user profile fields (name, phone, currency) in Firestore
  Future<void> updateUserProfile(String userId,
      {String? name, String? phone, String? currency}) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (currency != null) updates['currency'] = currency;
    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(userId).update(updates);

    // Also update Firebase Auth display name if name changed
    if (name != null && _auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(name);
    }
  }

  /// Change password (requires re-authentication with current password)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not signed in');
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  /// Delete account (requires re-authentication, then deletes Firestore data + Auth account)
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not signed in');
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: password);
    await user.reauthenticateWithCredential(cred);
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  /// Send a password reset email (only works for email/password accounts)
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) throw Exception('Email is required');
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  /// Get the currently signed-in Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
