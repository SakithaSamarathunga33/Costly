import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore database service.
/// Provides access to Firestore collections.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a Firestore collection reference
  CollectionReference<Map<String, dynamic>> collection(String name) {
    return _firestore.collection(name);
  }

  /// Firestore is always available once Firebase is initialized
  bool get isConnected => true;
}
