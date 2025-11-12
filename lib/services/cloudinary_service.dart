import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dgjxdmn2r';
  static const String apiKey = '354853456858872';
  static const String apiSecret = 'gEYNzoq9cYIhBuEskVodcZa68J8';

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'signalements_upload' // create in dashboard
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        return data['secure_url']; // URL of uploaded image
      } else {
        print('Upload failed: $resBody');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
