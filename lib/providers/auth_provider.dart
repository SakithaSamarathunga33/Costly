import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/constants.dart';

/// AuthProvider manages authentication state across the app
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  String get userId => _user?.id ?? '';
  String get userName => _user?.name ?? 'User';
  String get userEmail => _user?.email ?? '';
  String? get userProfilePicUrl => _user?.profilePicUrl;
  String get userPhone => _user?.phone ?? '';
  String get userCurrency => _user?.currency ?? 'USD';
  
  String get currencySymbol => getCurrencySymbol(userCurrency);

  /// Initialize: check if user is already signed in via Firebase Auth
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is already signed in
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        final user = await _authService.getUserById(firebaseUser.uid);
        if (user != null) {
          _user = user;
        }
      }
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _firebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _firebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _firebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile picture to Cloudinary and save URL to Firestore
  Future<bool> updateProfilePicture(XFile imageFile) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cloudinary = CloudinaryService();
      final previousUrl = _user!.profilePicUrl;
      await cloudinary.deleteImageBySecureUrl(previousUrl);

      final url = await cloudinary.uploadImage(
        imageFile,
        folder: 'profile_pictures',
      );

      if (url == null) {
        throw Exception('Failed to upload image');
      }

      // Save URL to Firestore
      await _authService.updateProfilePicUrl(_user!.id, url);

      // Update local user model
      _user = _user!.copyWith(profilePicUrl: url);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile (name, phone)
  Future<bool> updateProfile({String? name, String? phone}) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        _user!.id,
        name: name,
        phone: phone,
      );

      _user = _user!.copyWith(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user currency
  Future<bool> updateCurrency(String currency) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        _user!.id,
        currency: currency,
      );

      _user = _user!.copyWith(currency: currency);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password — returns true on success, sets _error on failure
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete account — returns true on success; caller should navigate to login
  Future<bool> deleteAccount({required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.deleteAccount(password: password);
      _isLoading = false;
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } finally {
      // Even if signOut fails (e.g. network), we clear local state
      _isLoading = false;
      _user = null;
      _error = null;
      notifyListeners();
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _firebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Invalid email or password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
