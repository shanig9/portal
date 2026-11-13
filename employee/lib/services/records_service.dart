import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class RecordsService {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  Uri _uri(String path) {
    if (baseUrl.isEmpty) {
      throw Exception('Document and application storage is not connected yet.');
    }
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r"/$"), "")}/api/$path');
  }

  Future<Map<String, String>> _headers() async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to access your documents and applications.');
    }
    return {
      'Authorization':
          'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken()}',
    };
  }

  Future<List<Map<String, dynamic>>> list(String resource) async {
    final response = await http
        .get(_uri(resource), headers: await _headers())
        .timeout(const Duration(seconds: 25));
    return (_decode(response)['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upload(Uint8List bytes, String filename) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw Exception('Choose a PDF up to 10 MB.');
    }
    final request = http.MultipartRequest('POST', _uri('documents'))
      ..headers.addAll(await _headers())
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      );
    final client = http.Client();
    try {
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(minutes: 2)),
      ).timeout(const Duration(minutes: 2));
      return _decode(response);
    } finally {
      client.close();
    }
  }

  Future<Uri> download(String id) async {
    final response = await http
        .get(_uri('documents/$id/download'), headers: await _headers())
        .timeout(const Duration(seconds: 25));
    return Uri.parse(_decode(response)['signedUrl'] as String);
  }

  Future<void> apply({
    required String title,
    required String company,
    required String location,
    required String documentId,
  }) async {
    final response = await http
        .post(
          _uri('applications'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({
            'jobKey': '$company::$title',
            'jobTitle': title,
            'company': company,
            'location': location,
            'documentId': documentId,
          }),
        )
        .timeout(const Duration(seconds: 25));
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The server returned an invalid response.');
    }
    if (response.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Storage request failed.');
    }
    return body;
  }
}
