import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Get the currently signed-in Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
