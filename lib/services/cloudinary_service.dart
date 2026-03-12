import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading images to Cloudinary
class CloudinaryService {
  static const String _cloudName = 'dr0rzmwoe';
  static const String _apiKey = '616978867843219';
  static const String _apiSecret = 'cnJ5_sMYx4SbWssDzzodyR7lSNc';

  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

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
