import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

// MongoDB connection URL - uses Railway internal hostname (accessible from Railway network)
const String mongoDbUrl =
    'mongodb://mongo:TNhehzeCnyBFbADXkXNUroawWkqWJPGi@mongodb.railway.internal:27017/test2?authSource=admin';

const String usersCollection = 'users';
const String transactionsCollection = 'transactions';

late Db db;
final uuid = const Uuid();

/// Hash password using SHA-256
String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

/// JSON response helper
Response jsonResponse(Object? body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  );
}

/// Error response helper
Response errorResponse(String message, {int statusCode = 400}) {
  return jsonResponse({'error': message}, statusCode: statusCode);
}

/// Convert MongoDB document - handle ObjectId
Map<String, dynamic> cleanDoc(Map<String, dynamic> doc) {
  final map = Map<String, dynamic>.from(doc);
  if (map['_id'] is ObjectId) {
    map['_id'] = (map['_id'] as ObjectId).oid;
  }
  return map;
}

void main() async {
  // Connect to MongoDB
  print('Connecting to MongoDB...');
  db = await Db.create(mongoDbUrl);
  await db.open();
  print('Connected to MongoDB successfully');

  final router = Router();

  // CORS preflight handler
  router.options('/<ignored|.*>', (Request request) {
    return Response.ok('', headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
  });

  // Health check
  router.get('/health', (Request request) {
    return jsonResponse({'status': 'ok'});
  });

  // ==================== AUTH ROUTES ====================

  /// POST /auth/register - Register a new user
  router.post('/auth/register', (Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final name = (body['name'] ?? '').toString().trim();
      final email = (body['email'] ?? '').toString().toLowerCase().trim();
      final password = (body['password'] ?? '').toString();

      if (name.isEmpty) return errorResponse('Name is required');
      if (email.isEmpty) return errorResponse('Email is required');
      if (password.length < 6) {
        return errorResponse('Password must be at least 6 characters');
      }

      // Check if user already exists
      final existing = await db.collection(usersCollection).findOne({'email': email});
      if (existing != null) {
        return errorResponse('An account with this email already exists');
      }

      final userId = uuid.v4();
      final user = {
        'userId': userId,
        'name': name,
        'email': email,
        'passwordHash': hashPassword(password),
      };

      await db.collection(usersCollection).insertOne(user);

      return jsonResponse({
        'userId': userId,
        'name': name,
        'email': email,
      });
    } catch (e) {
      return errorResponse('Registration failed: $e', statusCode: 500);
    }
  });

  /// POST /auth/login - Login with email and password
  router.post('/auth/login', (Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final email = (body['email'] ?? '').toString().toLowerCase().trim();
      final password = (body['password'] ?? '').toString();

      if (email.isEmpty) return errorResponse('Email is required');
      if (password.isEmpty) return errorResponse('Password is required');

      final result = await db.collection(usersCollection).findOne({
        'email': email,
        'passwordHash': hashPassword(password),
      });

      if (result == null) {
        return errorResponse('Invalid email or password', statusCode: 401);
      }

      return jsonResponse({
        'userId': result['userId'],
        'name': result['name'],
        'email': result['email'],
      });
    } catch (e) {
      return errorResponse('Login failed: $e', statusCode: 500);
    }
  });

  /// GET /auth/user/:userId - Get user by ID
  router.get('/auth/user/<userId>', (Request request, String userId) async {
    try {
      final result = await db.collection(usersCollection).findOne({'userId': userId});
      if (result == null) {
        return errorResponse('User not found', statusCode: 404);
      }
      return jsonResponse({
        'userId': result['userId'],
        'name': result['name'],
        'email': result['email'],
      });
    } catch (e) {
      return errorResponse('Failed to get user: $e', statusCode: 500);
    }
  });

  // ==================== TRANSACTION ROUTES ====================

  /// GET /transactions/:userId - Get all transactions for a user
  router.get('/transactions/<userId>', (Request request, String userId) async {
    try {
      final results = await db
          .collection(transactionsCollection)
          .find({'userId': userId})
          .toList();

      // Sort by date descending
      results.sort((a, b) {
        final dateA = a['date']?.toString() ?? '';
        final dateB = b['date']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      return jsonResponse(results.map(cleanDoc).toList());
    } catch (e) {
      return errorResponse('Failed to fetch transactions: $e', statusCode: 500);
    }
  });

  /// POST /transactions - Add a new transaction
  router.post('/transactions', (Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final title = (body['title'] ?? '').toString().trim();
      final amount = (body['amount'] ?? 0).toDouble();

      if (title.isEmpty) return errorResponse('Title is required');
      if (amount <= 0) return errorResponse('Amount must be greater than zero');

      final transactionId = uuid.v4();
      final transaction = {
        'transactionId': transactionId,
        'userId': body['userId'],
        'title': title,
        'amount': amount,
        'type': body['type'] ?? 'expense',
        'category': body['category'] ?? 'Other',
        'date': body['date'] ?? DateTime.now().toIso8601String(),
        'notes': (body['notes'] ?? '').toString().trim(),
      };

      await db.collection(transactionsCollection).insertOne(transaction);

      return jsonResponse(transaction);
    } catch (e) {
      return errorResponse('Failed to add transaction: $e', statusCode: 500);
    }
  });

  /// GET /analytics/summary?userId=X&month=YYYY-MM - Monthly totals by category
  router.get('/analytics/summary', (Request request) async {
    try {
      final params = request.url.queryParameters;
      final userId = params['userId'] ?? '';
      final month = params['month'] ?? ''; // e.g. '2026-04'

      if (userId.isEmpty || month.isEmpty) {
        return errorResponse('userId and month are required');
      }

      // Parse month prefix for date filtering (stored as ISO strings)
      final results = await db
          .collection(transactionsCollection)
          .find({'userId': userId})
          .toList();

      final monthResults = results.where((doc) {
        final dateStr = doc['date']?.toString() ?? '';
        return dateStr.startsWith(month);
      }).toList();

      double totalIncome = 0;
      double totalExpenses = 0;
      final Map<String, double> byCategory = {};

      for (final tx in monthResults) {
        final amount = (tx['amount'] ?? 0).toDouble();
        final type = tx['type']?.toString() ?? 'expense';
        final category = tx['category']?.toString() ?? 'Other';

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpenses += amount;
          byCategory[category] = (byCategory[category] ?? 0) + amount;
        }
      }

      return jsonResponse({
        'userId': userId,
        'month': month,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netCashFlow': totalIncome - totalExpenses,
        'byCategory': byCategory,
        'transactionCount': monthResults.length,
      });
    } catch (e) {
      return errorResponse('Failed to get analytics: $e', statusCode: 500);
    }
  });

  /// DELETE /transactions/:transactionId - Delete a transaction
  router.delete('/transactions/<transactionId>',
      (Request request, String transactionId) async {
    try {
      await db
          .collection(transactionsCollection)
          .deleteOne({'transactionId': transactionId});
      return jsonResponse({'message': 'Transaction deleted'});
    } catch (e) {
      return errorResponse('Failed to delete transaction: $e', statusCode: 500);
    }
  });

  // Add CORS middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Start the server
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');
}
