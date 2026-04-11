import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Thin HTTP client for the optional Dart/Shelf backend server.
/// All calls fail silently — Firestore is always the source of truth.
class BackendService {
  static final BackendService _instance = BackendService._();
  factory BackendService() => _instance;
  BackendService._();

  final _client = http.Client();
  final String _base = kBackendBaseUrl;

  /// Returns true if the backend server is reachable.
  Future<bool> isReachable() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch monthly analytics summary from the backend.
  /// Returns null if the backend is unreachable or returns an error.
  Future<Map<String, dynamic>?> getAnalyticsSummary({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('$_base/analytics/summary').replace(
        queryParameters: {
          'userId': userId,
          'month': '$year-${month.toString().padLeft(2, '0')}',
        },
      );
      final res = await _client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Mirror a transaction write to MongoDB (best-effort, fire-and-forget).
  Future<void> syncTransaction(Map<String, dynamic> txData) async {
    try {
      await _client
          .post(
            Uri.parse('$_base/transactions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(txData),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Intentionally swallowed — Firestore is source of truth
    }
  }
}
