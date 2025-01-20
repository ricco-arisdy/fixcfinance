import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://cfinance.software-cgs.my.id/user/transaction';

  static Future<bool> addTransaction({
    required String idUser,
    required String idTipe,
    required String idKategori,
    required String nominal,
    required String tanggalTransaksi,
    String? deskripsi,
  }) async {
    final url = Uri.parse('$baseUrl/add?action=add');
    print("Request URL: $url");

    try {
      final body = jsonEncode({
        'id_user': idUser,
        'id_tipe': idTipe,
        'id_kategori': idKategori,
        'nominal': nominal,
        'tanggal_transaksi': tanggalTransaksi,
        'deskripsi': deskripsi ?? "", // Kirim string kosong jika null
      });
      print("Request Payload: $body");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
    } catch (e) {
      print("Error adding transaction: $e");
    }
    return false;
  }

  /// Fungsi untuk mengambil semua kategori
  static Future<List<dynamic>> fetchCategories() async {
    final url = Uri.parse(
        'https://cfinance.software-cgs.my.id/user/transaction/getCategories?action=getCategories');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Fetched categories: $data"); // Debug log
        if (data['status'] == 'success') {
          return data['data']; // Mengembalikan daftar kategori
        }
      } else {
        print("Error fetching categories: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
    return [];
  }
}
