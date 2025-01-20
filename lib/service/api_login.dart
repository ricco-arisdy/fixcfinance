import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://cfinance.software-cgs.my.id/user/login?action=check";

  // Fungsi untuk login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse(baseUrl); // Gunakan baseUrl langsung
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      // Jika respons berhasil
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // Simpan id_user ke SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('id_user', data['user']['id_user'].toString());

          return data; // Kembalikan data hasil login
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Login failed'
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to connect. Status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'An error occurred: $e'};
    }
  }

  // Fungsi untuk mendapatkan id_user dari SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_user');
  }
}
