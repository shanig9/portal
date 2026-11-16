import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';

class ApplicationConfirmationPending implements Exception {
  const ApplicationConfirmationPending();
}

class RecordsService {
  static String get baseUrl => ApiConfig.baseUrl;
  Uri _uri(String path) {
    if (baseUrl.isEmpty) {
      throw Exception(
        'Documents and applications are unavailable because the app has no server connection configured.',
      );
    }
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r"/$"), "")}/api/$path');
  }

  Future<Map<String, String>> _headers() async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to access your documents and applications.');
    }
    final token = await FirebaseAuth.instance.currentUser!.getIdToken().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        'Sign-in could not be refreshed. Check your phone internet connection and try again.',
      ),
    );
    if (token == null) throw Exception('Sign in again to continue.');
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<Map<String, dynamic>>> list(String resource) async {
    final response = await http
        .get(_uri(resource), headers: await _headers())
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw Exception(
            'The Career Connect server did not respond. For USB testing, keep your phone connected and restart USB forwarding.',
          ),
        );
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

  Future<String> chat(String applicationId) async {
    final response = await http
        .post(
          _uri('applications/$applicationId/chat'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 25));
    return _decode(response)['chatId'] as String;
  }

  Future<void> apply({
    required String jobId,
    required String title,
    required String company,
    required String location,
    required String documentId,
  }) async {
    final headers = {...await _headers(), 'Content-Type': 'application/json'};
    try {
      final response = await http
          .post(
            _uri('applications'),
            headers: headers,
            body: jsonEncode({
              'jobKey': jobId,
              'jobTitle': title,
              'company': company,
              'location': location,
              'documentId': documentId,
            }),
          )
          .timeout(const Duration(seconds: 60));
      _decode(response);
    } on TimeoutException {
      return _confirmApplication(jobId, headers);
    } on http.ClientException {
      return _confirmApplication(jobId, headers);
    }
  }

  Future<void> _confirmApplication(
    String jobId,
    Map<String, String> headers,
  ) async {
    // A lost response does not mean the database insert failed.
    try {
      final response = await http
          .get(_uri('applications'), headers: headers)
          .timeout(const Duration(seconds: 30));
      final items = _decode(response)['items'] as List;
      if (items.any((item) => item['job_key'] == jobId)) return;
    } catch (_) {
      // Leave the outcome unknown if the confirmation request also fails.
    }
    throw const ApplicationConfirmationPending();
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
