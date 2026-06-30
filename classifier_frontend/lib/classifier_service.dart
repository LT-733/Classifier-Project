import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ClassifierService {
  final String _baseUrl = 'https://classifier-project-production.up.railway.app';

  Future<Map<String, dynamic>> predictItem({
    XFile? imageFile,
    Uint8List? imageBytes,
    required List<String> zones,
  }) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);

    try {
      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'upload.jpg',
        ));
      } else if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));
      }

      request.fields['zones'] = jsonEncode(zones);

      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'message': 'Backend error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }
}