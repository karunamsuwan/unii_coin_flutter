import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CoinSearchService {
  Future<Map<String, dynamic>> getCoinsSearch(String value) async {
    final baseUrl = dotenv.env['API_BASE_URL'];

    final url = Uri.parse('$baseUrl/v2/coins?search=$value');

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
