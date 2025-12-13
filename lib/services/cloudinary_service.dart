import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dklrtb98n';
  static const String uploadPreset = 'Abjad_';

  static Future<String?> uploadImage(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    } else {
      // مفيد للتصحيح
      // print('Cloudinary error: $body');
      return null;
    }
  }

  // ✅ رفع الملفات الصوتية
  static Future<String?> uploadAudio(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload', // Cloudinary يعامل الصوت كـ video
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['resource_type'] = 'video'; // مهم للملفات الصوتية
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    } else {
      print('Cloudinary audio upload error: $body');
      return null;
    }
  }
}
