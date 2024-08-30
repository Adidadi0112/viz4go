import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'http://localhost:5000';

  Future<List<dynamic>> fetchGoTerms(List<String> goTermIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/go/terms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'go_term_ids': goTermIds}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load GO terms');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
