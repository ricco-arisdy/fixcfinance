import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServiceEdit {
  static final String baseUrl = "https://cfinance.software-cgs.my.id";

  // Static method untuk update transaction
  static Future<Map<String, dynamic>> updateTransaction({
    required String idUser,
    required String idTransaksi,
    String? idTipe,
    String? nominal,
    String? deskripsi,
    String? tanggalTransaksi,
  }) async {
    final url = Uri.parse("$baseUrl/user/transaction/update?action=update");

    final Map<String, dynamic> body = {
      "id_user": idUser,
      "id_transaksi": idTransaksi,
      if (idTipe != null) "id_tipe": idTipe,
      if (nominal != null) "nominal": nominal,
      if (deskripsi != null) "deskripsi": deskripsi,
      if (tanggalTransaksi != null) "tanggal_transaksi": tanggalTransaksi,
    };

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Failed with status code ${response.statusCode}",
          "response": json.decode(response.body),
        };
      }
    } catch (e) {
      return {
        "status": "error",
        "message": "An error occurred: $e",
      };
    }
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
