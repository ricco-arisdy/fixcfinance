import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHomeDeleteService {
  static const String baseUrl = 'https://cfinance.software-cgs.my.id'; // Sesuaikan URL Anda

  static Future<Map<String, dynamic>> deleteTransaction(
      String idUser, String idTransaksi) async {
    final url = Uri.parse('$baseUrl/user/transaction/delete?action=delete');

    try {
      // Body untuk request
      final body = jsonEncode({
        'id_user': idUser,
        'id_transaksi': idTransaksi,
      });

      // Mengirim permintaan DELETE
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Parsing respons
      if (response.statusCode == 200) {
        return {'status': true, 'message': 'Transaction deleted successfully'};
      } else {
        final errorData = jsonDecode(response.body);
        return {'status': false, 'message': errorData['message']};
      }
    } catch (e) {
      return {'status': false, 'message': 'Error: $e'};
    }
  }
}
