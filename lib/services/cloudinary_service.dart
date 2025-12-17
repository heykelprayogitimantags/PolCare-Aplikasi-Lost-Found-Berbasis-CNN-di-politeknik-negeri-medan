import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "Ydoqsyiojj"; 
  static const String uploadPreset = "polmedcare";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['secure_url']; 
      } else {
        print(" Upload gagal: ${response.statusCode}");
        print(responseData);
        return null;
      }
    } catch (e) {
      print(" Error upload ke Cloudinary: $e");
      return null;
    }
  }
}
