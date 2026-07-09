// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CloudinaryService {
  static const String _cloudName = 'rieiwdmi';
  static const String _apiKey = '793299167768428';
  static const String _apiSecret = 'ExjACG8uduOowX6ADDxoOtI2aCg';
  static const String _uploadPreset = 'jewellery_uploads';

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': return 'image/jpeg';
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'bmp': return 'image/bmp';
      case 'svg': return 'image/svg+xml';
      default: return 'image/jpeg';
    }
  }

  static Future<String?> uploadBytes(Uint8List bytes, String fileName) async {
    try {
      print('📸 Uploading ${bytes.length} bytes to Cloudinary...');
      
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(fileName);
      
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      
      // Generate a clean public_id with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = 'jewellery_${timestamp}';
      
      print('📁 Clean public_id: $cleanName');
      print('📁 MIME type: $mimeType');
      
      // ============================================================
      // FORCE both asset_folder and public_id
      // This overrides any account-level defaults
      // ============================================================
      final body = {
        'upload_preset': _uploadPreset,
        'file': 'data:$mimeType;base64,$base64Image',
        'public_id': cleanName,
        'asset_folder': 'jewellery_items',  // ← Force explicit folder
      };
      
      print('📤 Sending request to Cloudinary...');
      print('📦 Request body: ${body.keys}');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('⏰ Upload timed out after 30 seconds');
        },
      );
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['secure_url'] as String;
        print('✅ Image uploaded successfully!');
        print('📎 URL: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await uploadBytes(bytes, imageFile.path.split('/').last);
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  static Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }
}