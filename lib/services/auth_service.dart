import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Service handling user authentication with Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    final idToken = googleUser.authentication.idToken;

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
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
  }

  /// Update user's profile picture URL in Firestore
  Future<void> updateProfilePicUrl(String userId, String url) async {
    await _firestore.collection('users').doc(userId).update({
      'profilePicUrl': url,
    });
  }

  /// Update user profile fields (name, phone) in Firestore
  Future<void> updateUserProfile(String userId,
      {String? name, String? phone}) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(userId).update(updates);

    // Also update Firebase Auth display name if name changed
    if (name != null && _auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(name);
    }
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
    try {
      // Add timeout to prevent hanging if Google Sign In is unresponsive
      await GoogleSignIn.instance.signOut().timeout(const Duration(seconds: 3));
    } catch (e) {
      // Continue with Firebase sign out even if Google sign out fails
      print('Google sign out failed: $e');
    }
    await _auth.signOut();
  }
}
