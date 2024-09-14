import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:viz4go_frontend/models/Node.dart';

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:5000';

  Future<List<Node>> fetchGoTermsByNodeIndex(Map<String, int> nodeIndex) async {
  try {
    List<String> termIds = nodeIndex.keys.toList();

    final uri = Uri.http(
      '127.0.0.1:5000',  
      '/api/go/terms',
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'term_ids': termIds}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body) as List<dynamic>;
      return responseData.map((term) => Node.fromJson(term)).toList();
    } else if (response.statusCode == 400) {
      throw Exception('No term IDs provided');
    } else if (response.statusCode == 404) {
      throw Exception('No terms found for the given IDs');
    } else {
      throw Exception('Failed to load GO terms');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}



  Future<List<dynamic>> fetchGoConnections(List<String> goTermIds) async {
    try {
      print(goTermIds);
      final response = await http.post(
        Uri.parse('$_baseUrl/api/go/connections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'start_node': goTermIds}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load GO terms');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
