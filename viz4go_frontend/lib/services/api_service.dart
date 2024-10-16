import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:viz4go_frontend/models/node.dart';
import 'package:http_parser/http_parser.dart';

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
        final List<dynamic> responseData =
            jsonDecode(response.body) as List<dynamic>;
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

  Future<Map<String, dynamic>?> sendNodeConnectionsRequest(PlatformFile file1,
      PlatformFile file2, PlatformFile file3, double score) async {
    var url = Uri.parse('$_baseUrl/api/go/connections_csv');

    var request = http.MultipartRequest('POST', url);

    // Dodanie wartości score do formularza
    request.fields['score'] = score.toString();

    // Dodanie plików CSV, jeśli istnieją
    if (file1 != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file1',
        file1.bytes!,
        filename: file1.name,
        contentType: MediaType('text', 'csv'),
      ));
    }
    if (file2 != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file2',
        file2.bytes!,
        filename: file2.name,
        contentType: MediaType('text', 'csv'),
      ));
    }
    if (file3 != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file3',
        file3.bytes!,
        filename: file3.name,
        contentType: MediaType('text', 'csv'),
      ));
    }

    // Wysłanie żądania
    try {
      var streamedResponse = await request.send();

      // Odbieranie odpowiedzi
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parsowanie odpowiedzi do formatu JSON
        var data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Success: $data');
        return data;
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}
