import 'dart:convert';
import 'dart:io';

/// Creates a sample user in Firebase Auth and Firestore using REST APIs.
///
/// Sample credentials:
///   Email: test@example.com
///   Password: test123456

const String apiKey = 'AIzaSyCp2rTZsOSFBSfR8g8Rgy8QvarIfFp9oTc';
const String projectId = 'costly-fe754';

const String sampleEmail = 'test@example.com';
const String samplePassword = 'test123456';
const String sampleName = 'Test User';

Future<void> main() async {
  print('Creating sample user...');
  print('Email: $sampleEmail');
  print('Password: $samplePassword');
  print('');

  final client = HttpClient();

  try {
    // Step 1: Create user in Firebase Auth
    print('Step 1: Creating user in Firebase Auth...');
    final signUpUrl = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final signUpRequest = await client.postUrl(signUpUrl);
    signUpRequest.headers.set('Content-Type', 'application/json');
    signUpRequest.write(jsonEncode({
      'email': sampleEmail,
      'password': samplePassword,
      'returnSecureToken': true,
    }));

    final signUpResponse = await signUpRequest.close();
    final signUpBody = await signUpResponse.transform(utf8.decoder).join();
    final signUpData = jsonDecode(signUpBody) as Map<String, dynamic>;

    if (signUpResponse.statusCode != 200) {
      final error = signUpData['error']?['message'] ?? 'Unknown error';
      if (error == 'EMAIL_EXISTS') {
        print('User already exists! Logging in instead...');
        // Login to get the token and UID
        final loginUrl = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
        );
        final loginRequest = await client.postUrl(loginUrl);
        loginRequest.headers.set('Content-Type', 'application/json');
        loginRequest.write(jsonEncode({
          'email': sampleEmail,
          'password': samplePassword,
          'returnSecureToken': true,
        }));
        final loginResponse = await loginRequest.close();
        final loginBody = await loginResponse.transform(utf8.decoder).join();
        final loginData = jsonDecode(loginBody) as Map<String, dynamic>;

        if (loginResponse.statusCode != 200) {
          print('Failed to login: ${loginData['error']?['message']}');
          exit(1);
        }

        print('Logged in successfully!');
        print('UID: ${loginData['localId']}');
        await _updateProfile(client, loginData['idToken'], sampleName);
        await _createFirestoreProfile(client, loginData['idToken'], loginData['localId']);
        print('\nSample user ready!');
        print('---');
        print('Email: $sampleEmail');
        print('Password: $samplePassword');
        exit(0);
      }
      print('Failed to create user: $error');
      exit(1);
    }

    final uid = signUpData['localId'];
    final idToken = signUpData['idToken'];
    print('User created! UID: $uid');

    // Step 2: Update display name
    print('Step 2: Setting display name...');
    await _updateProfile(client, idToken, sampleName);

    // Step 3: Create user profile in Firestore
    print('Step 3: Creating Firestore profile...');
    await _createFirestoreProfile(client, idToken, uid);

    print('\nSample user created successfully!');
    print('---');
    print('Email: $sampleEmail');
    print('Password: $samplePassword');
  } catch (e) {
    print('Error: $e');
    exit(1);
  } finally {
    client.close();
  }
}

Future<void> _updateProfile(HttpClient client, String idToken, String name) async {
  final updateUrl = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey',
  );
  final updateRequest = await client.postUrl(updateUrl);
  updateRequest.headers.set('Content-Type', 'application/json');
  updateRequest.write(jsonEncode({
    'idToken': idToken,
    'displayName': name,
    'returnSecureToken': false,
  }));
  final updateResponse = await updateRequest.close();
  await updateResponse.drain();
  print('Display name set to: $name');
}

Future<void> _createFirestoreProfile(HttpClient client, String idToken, String uid) async {
  final firestoreUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users?documentId=$uid',
  );
  final fsRequest = await client.postUrl(firestoreUrl);
  fsRequest.headers.set('Content-Type', 'application/json');
  fsRequest.headers.set('Authorization', 'Bearer $idToken');
  fsRequest.write(jsonEncode({
    'fields': {
      'name': {'stringValue': sampleName},
      'email': {'stringValue': sampleEmail},
    },
  }));
  final fsResponse = await fsRequest.close();
  final fsBody = await fsResponse.transform(utf8.decoder).join();

  if (fsResponse.statusCode == 200 || fsResponse.statusCode == 409) {
    print('Firestore profile created!');
  } else {
    print('Firestore warning (${fsResponse.statusCode}): $fsBody');
    print('(User can still login - Firestore profile will be created on first login)');
  }
}
