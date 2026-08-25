import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });

  final String secureUrl;
  final String publicId;
}

class CloudinaryUploadService {
  CloudinaryUploadService._();

  static final http.Client _client = http.Client();

  /// Sube bytes de imagen directamente a Cloudinary usando el preset unsigned "chamba"
  static Future<CloudinaryUploadResult> uploadImageBytes({
    required List<int> bytes,
    required String fileName,
    required String folder,
  }) async {
    final cloudName = ApiConstants.cloudinaryCloudName.trim();
    final uploadPreset = ApiConstants.cloudinaryUploadPreset.trim();

    debugPrint('[Cloudinary] Subiendo imagen: $fileName a folder: $folder');

    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = payload['secure_url'] as String?;
      final publicId = payload['public_id'] as String?;

      if (response.statusCode >= 400 || secureUrl == null || publicId == null) {
        final detail = (payload['error'] as Map<String, dynamic>?)?['message'] as String? ??
            'No se pudo subir la imagen a Cloudinary';
        debugPrint('[Cloudinary] Error: $detail');
        throw Exception(detail);
      }

      debugPrint('[Cloudinary] Subida exitosa: $secureUrl');
      return CloudinaryUploadResult(secureUrl: secureUrl, publicId: publicId);
    } catch (e) {
      debugPrint('[Cloudinary] Excepción en subida: $e');
      rethrow;
    }
  }
}
