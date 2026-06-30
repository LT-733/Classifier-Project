import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ClassifierService {
  final String _baseUrl = 'https://ltcai-zone-classifier.hf.space';

  /// Sends the selected image and target zones array to the FastAPI NPU pipeline.
  Future<Map<String, dynamic>> predictItem({
    required File imageFile,
    required List<String> zones,
  }) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);

    try {
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      request.fields['zones'] = jsonEncode(zones);

      print('Dispatched multipart request to $_baseUrl/predict...');
      
      // Connection/upload timeout window extended to 60 seconds
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );
      
      // Extraction timeout window extended to 60 seconds
      final response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(minutes: 5),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': 'error',
          'message': 'Backend execution failed with code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to communicate with NPU server: $e',
      };
    }
  }
}