import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading images to Cloudinary.
///
/// Credentials are **not** stored in the repo. Pass at build/run time:
/// `--dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_API_KEY=... --dart-define=CLOUDINARY_API_SECRET=...`
/// GitHub Actions: set repository secrets with the same names.
class CloudinaryService {
  static const String _cloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String _apiKey = String.fromEnvironment('CLOUDINARY_API_KEY');
  static const String _apiSecret =
      String.fromEnvironment('CLOUDINARY_API_SECRET');

  /// True when all three compile-time defines are non-empty.
  static bool get isConfigured =>
      _cloudName.isNotEmpty &&
      _apiKey.isNotEmpty &&
      _apiSecret.isNotEmpty;

  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  void _ensureConfigured() {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary is not configured. Build or run with '
        '--dart-define=CLOUDINARY_CLOUD_NAME=... '
        '--dart-define=CLOUDINARY_API_KEY=... '
        '--dart-define=CLOUDINARY_API_SECRET=...',
      );
    }
  }

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
  }

  /// Upload an image file to Cloudinary and return the secure URL
  Future<String?> uploadImage(XFile imageFile, {String? folder}) async {
    _ensureConfigured();
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Build parameters for signature
      final params = <String, String>{
        'timestamp': timestamp.toString(),
      };
      if (folder != null) {
        params['folder'] = folder;
      }

      // Generate signature
      final signature = _generateSignature(params);

      // Build multipart request
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Determine content type from file extension
      final mimeType = _getMimeType(imageFile.name);

      // Read file bytes and attach
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
          contentType: MediaType(mimeType.$1, mimeType.$2),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Cloudinary response status: ${response.statusCode}');
      debugPrint('Cloudinary response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['secure_url'] as String;
      } else {
        final errorData = json.decode(response.body);
        final errorMsg =
            errorData['error']?['message'] ?? 'Upload failed (${response.statusCode})';
        debugPrint('Cloudinary upload error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      rethrow;
    }
  }

  /// Parses [public_id] from a `res.cloudinary.com` delivery URL (supports optional transforms + version).
  static String? publicIdFromSecureUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('cloudinary.com')) return null;
    final segs = uri.pathSegments;
    final u = segs.indexOf('upload');
    if (u < 0 || u + 1 >= segs.length) return null;
    var rest = segs.sublist(u + 1);
    while (rest.isNotEmpty) {
      final s = rest.first;
      if (RegExp(r'^v\d+$').hasMatch(s)) {
        rest = rest.sublist(1);
        break;
      }
      if (s.contains(',') || _looksLikeCloudinaryTransformSegment(s)) {
        rest = rest.sublist(1);
        continue;
      }
      break;
    }
    if (rest.isEmpty) return null;
    final lastSeg = rest.last;
    final withoutExt =
        lastSeg.replaceFirst(RegExp(r'\.[a-z0-9]+$', caseSensitive: false), '');
    if (rest.length == 1) return withoutExt;
    return '${rest.sublist(0, rest.length - 1).join('/')}/$withoutExt';
  }

  static bool _looksLikeCloudinaryTransformSegment(String s) {
    if (s.isEmpty) return false;
    return s.startsWith('c_') ||
        s.startsWith('w_') ||
        s.startsWith('h_') ||
        s.startsWith('q_') ||
        s.startsWith('f_') ||
        s.startsWith('e_') ||
        s.startsWith('b_') ||
        s.startsWith('t_') ||
        s.startsWith('a_') ||
        s.startsWith('d_') ||
        s.startsWith('l_') ||
        s.startsWith('u_') ||
        s.startsWith('x_') ||
        s.startsWith('y_') ||
        s.startsWith('z_') ||
        s.startsWith('fl_') ||
        s.startsWith('ar_') ||
        s.startsWith('bo_') ||
        s.startsWith('pg_') ||
        s.startsWith('so_');
  }

  /// Deletes the asset at [secureUrl] from Cloudinary (no-op if URL is null or not Cloudinary).
  /// Errors are logged only; callers should not depend on success for UX.
  Future<void> deleteImageBySecureUrl(String? secureUrl) async {
    final publicId = publicIdFromSecureUrl(secureUrl);
    if (publicId == null) return;
    if (!isConfigured) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };
      final signature = _generateSignature(params);

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['result'] as String?;
        debugPrint('Cloudinary destroy: $result ($publicId)');
      } else {
        debugPrint(
          'Cloudinary destroy failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary destroy exception: $e');
    }
  }

  /// Get MIME type tuple from filename
  (String, String) _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return ('image', 'jpeg');
      case 'png':
        return ('image', 'png');
      case 'gif':
        return ('image', 'gif');
      case 'webp':
        return ('image', 'webp');
      default:
        return ('image', 'jpeg');
    }
  }

  /// Generate SHA-1 signature for Cloudinary signed upload
  String _generateSignature(Map<String, String> params) {
    // Sort parameters alphabetically and join with &
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys.map((k) => '$k=${params[k]}').join('&');

    // Append API secret
    final toSign = '$paramString$_apiSecret';

    // Generate SHA-1 hash
    final bytes = utf8.encode(toSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
