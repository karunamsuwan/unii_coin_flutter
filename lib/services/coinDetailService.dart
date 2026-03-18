import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CoinDetailService {
  Future<Map<String, dynamic>> getCoinsDetail(String uuid) async {
    final baseUrl = dotenv.env['API_BASE_URL'];

    final url = Uri.parse('$baseUrl/v2/coin/$uuid');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data["data"];
    } else {
      throw Exception('Failed');
    }
  }
}
