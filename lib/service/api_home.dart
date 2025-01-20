import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiHomeService {
  static const String baseUrl =
      "https://cfinance.software-cgs.my.id/user/transaction/read"; // URL dasar API

  // Fungsi untuk mengambil semua transaksi
  static Future<Map<String, dynamic>> fetchAllTransactions() async {
    final url = Uri.parse('$baseUrl?action=read'); // URL yang benar
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message":
              "Failed to fetch all transactions. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"status": "error", "message": "An error occurred: $e"};
    }
  }

  // Fungsi untuk mengambil transaksi berdasarkan id_user
  static Future<Map<String, dynamic>> fetchUserTransactions(
      String idUser) async {
    final url =
        Uri.parse('$baseUrl?action=read&id_user=$idUser'); // URL yang benar
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message":
              "Failed to fetch user transactions. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"status": "error", "message": "An error occurred: $e"};
    }
  }

  static Future<Map<String, dynamic>> fetchTransactionsByDateRange(
      String startDate, String endDate,
      {String? idUser}) async {
    final queryParameters = {
      'action': 'read',
      'start_date': startDate,
      'end_date': endDate,
      if (idUser != null)
        'id_user': idUser, // Opsional: filter berdasarkan id_user
    };

    final url = Uri.https(
      'cfinance.software-cgs.my.id', // Domain API Anda
      '/user/transaction/read', // Path API
      queryParameters,
    );

    debugPrint("Fetching transactions with URL: $url");

    try {
      final response = await http.get(url);
      debugPrint("API Response: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Decode respons JSON
      } else {
        debugPrint(
            "Failed to fetch transactions. Status code: ${response.statusCode}");
        return {
          "status": "error",
          "message":
              "Failed to fetch transactions. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      debugPrint("An error occurred: $e");
      return {"status": "error", "message": "An error occurred: $e"};
    }
  }

  /// Fetch transactions by `id_tipe` (Income or Expense)
  static Future<Map<String, dynamic>> fetchTransactionsByType(
      String idTipe) async {
    // Debug log untuk melihat id_tipe
    debugPrint("Fetching transactions by id_tipe: $idTipe");

    // Pastikan idTipe tidak kosong
    if (idTipe.isEmpty) {
      debugPrint("Error: idTipe is empty or invalid");
      return {"status": "error", "message": "Invalid id_tipe"};
    }

    // Pastikan `baseUrl` hanya berisi domain
    const String baseUrl = "cfinance.software-cgs.my.id";

    // Bangun URL dengan parameter id_tipe
    final url = Uri.https(
      baseUrl, // Domain tanpa path
      '/user/transaction/read', // Path
      {
        'action': 'read',
        'id_tipe': idTipe, // Parameter id_tipe
      },
    );

    // Debug log URL yang dihasilkan
    debugPrint("Constructed URL: $url");

    try {
      // Kirim request GET
      final response = await http.get(url);

      // Debug log untuk response
      debugPrint("Response: ${response.statusCode}, Body: ${response.body}");

      // Periksa status kode
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Decode JSON jika berhasil
      } else {
        // Debug untuk status kode selain 200
        debugPrint("Failed with status code: ${response.statusCode}");
        return {
          "status": "error",
          "message":
              "Failed to fetch transactions. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      // Debug log untuk error yang terjadi
      debugPrint("Error occurred: $e");
      return {"status": "error", "message": "An error occurred: $e"};
    }
  }
}
