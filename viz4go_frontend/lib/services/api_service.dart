import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:viz4go_frontend/models/node.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:5000';

  Future<List<Node>> fetchGoTermsByNodeIndex(Map<String, int> nodeIndex) async {
    try {
      print(
          'Fetching GO terms for node index: $nodeIndex endpoint /api/go/terms');
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
      print(
          'Fetching GO connections for term IDs: $goTermIds endpoint /api/go/connections');
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
    final url = Uri.parse('$_baseUrl/api/go/connections_csv');
    final request = http.MultipartRequest('POST', url);

    request.fields['score'] = score.toString();
    // (opcjonalnie) możesz dopisać:
    // request.fields['direction'] = 'up';
    // request.fields['max_depth'] = '3';
    // request.fields['edge_types'] = 'is_a,part_of';

    if (file1.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file1',
        file1.bytes!,
        filename: file1.name,
        contentType: MediaType('text', 'csv'),
      ));
    }
    if (file2.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file2',
        file2.bytes!,
        filename: file2.name,
        contentType: MediaType('text', 'csv'),
      ));
    }
    if (file3.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file3',
        file3.bytes!,
        filename: file3.name,
        contentType: MediaType('text', 'csv'),
      ));
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        print('Error: ${response.statusCode} → ${response.body}');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Obsłuż 2 przypadki: nowy (z kluczem "proteins") i ewentualnie stary (płaski)
      Map<String, dynamic> proteinsMap;
      if (data.containsKey('proteins')) {
        final Map<String, dynamic> proteins =
            data['proteins'] as Map<String, dynamic>;
        // Spłaszcz: protein -> edges (porzuć missing_terms w payloadzie dla UI)
        proteinsMap = proteins.map((k, v) {
          if (v is Map && v.containsKey('edges')) {
            return MapEntry(k, v['edges']);
          }
          return MapEntry(k, v); // fallback
        });
      } else {
        // fallback: zakładamy już płaską mapę protein -> edges
        proteinsMap = data;
      }

      return proteinsMap; // <- to dostaje HomeScreen._generateGraphFromCsv
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchProteinClusters(
    Map<String, List<String>> proteinToGo, {
    // nowości:
    String mode = "semantic", // "semantic" | "shared_go"
    String measure = "wang", // dla semantic
    double? threshold, // np. 0.6
    int? knn, // alternatywa dla threshold
    double resolution = 1.0,
    // wsteczna kompatybilność:
    int minShared = 2,
    String algo = "louvain",
  }) async {
    final uri = Uri.parse('$_baseUrl/api/cluster/protein');
    final body = <String, dynamic>{
      'protein_to_go': proteinToGo,
      'algo': algo,
      'mode': mode,
      'resolution': resolution,
    };

    if (mode == 'semantic') {
      body['measure'] = measure;
      if (threshold != null) body['threshold'] = threshold;
      if (knn != null) body['knn'] = knn;
    } else {
      body['min_shared'] = minShared;
    }

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) throw Exception(resp.body);
    final Map<String, dynamic> json = jsonDecode(resp.body);

    // Zwróć clusters i edges
    return {
      'clusters': (json['clusters'] as Map)
          .map((k, v) => MapEntry(k as String, v as int)),
      'edges': json['edges'] as List<dynamic>? ?? [],
    };
  }
}
