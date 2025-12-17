import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.110.250.60:5000';

  static Future<List<String>> searchByImage(File image) async {
    try {
      debugPrint("📤 Mengirim gambar ke backend AI...");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/search-by-image'),
      );

      // Attach file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
        ),
      );

      // Set timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server tidak merespons');
        },
      );

      // Parse response
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📥 Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<String> matchedIds =
              List<String>.from(data['matched_ids'] ?? []);

          debugPrint("✅ Ditemukan ${matchedIds.length} hasil cocok");

          // Debug: print similarity scores
          if (data['details'] != null) {
            debugPrint("📊 Top matches:");
            for (var detail in data['details']) {
              debugPrint(
                  "  - ${detail['title']}: ${detail['similarity'].toStringAsFixed(3)}");
            }
          }

          return matchedIds;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      debugPrint("❌ Tidak dapat terhubung ke server");
      throw Exception(
          'Tidak dapat terhubung ke server. Pastikan backend sedang berjalan.');
    } on http.ClientException {
      debugPrint("❌ Network error");
      throw Exception('Kesalahan jaringan. Periksa koneksi internet Anda.');
    } catch (e) {
      debugPrint("❌ Error: $e");
      rethrow;
    }
  }

  /// Search by image menggunakan base64 (alternative)
  static Future<List<String>> searchByImageBase64(File image) async {
    try {
      debugPrint("📤 Mengirim gambar (base64) ke backend AI...");

      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse('$baseUrl/search-by-image'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image_base64': base64Image,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      debugPrint("📥 Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<String> matchedIds =
              List<String>.from(data['matched_ids'] ?? []);
          debugPrint("✅ Ditemukan ${matchedIds.length} hasil cocok");
          return matchedIds;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      rethrow;
    }
  }

  /// Preprocess all images (jalankan sekali saat setup)
  static Future<Map<String, dynamic>> preprocessAllImages() async {
    try {
      debugPrint("🔄 Memulai preprocessing semua gambar...");

      final response = await http.post(
        Uri.parse('$baseUrl/preprocess-all-images'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(minutes: 10), // Bisa lama jika banyak gambar
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint(
            "✅ Preprocessing selesai: ${data['processed']} berhasil, ${data['failed']} gagal");
        return data;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Preprocessing error: $e");
      rethrow;
    }
  }

  /// Health check
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Server healthy: ${data['model']}");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Server not responding: $e");
      return false;
    }
  }
}
