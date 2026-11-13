import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class Reel {
  Reel.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      url = json['url'] as String,
      type = json['type'] as String,
      caption = json['caption'] as String,
      author = json['author'] as String;
  final String id, url, type, caption, author;
}

class ReelsPage {
  ReelsPage(this.items, this.nextCursor);
  final List<Reel> items;
  final String? nextCursor;
}

class ReelsService {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  Uri _uri([Map<String, String>? query]) {
    if (baseUrl.isEmpty) {
      throw Exception('The reels service is not connected yet.');
    }
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r"/$"), "")}/api/reels')
        .replace(queryParameters: query);
  }

  Future<ReelsPage> list({String? cursor}) async {
    final response = await http
        .get(_uri({'limit': '10', 'cursor': ?cursor}))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    return ReelsPage(
      (body['items'] as List).map((item) => Reel.fromJson(item)).toList(),
      body['nextCursor'] as String?,
    );
  }

  Future<Reel> upload(Uint8List bytes, String name, String caption) async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to upload a reel.');
    }
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final mime = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
    }[name.split('.').last.toLowerCase()];
    if (mime == null) throw Exception('Unsupported image or video type.');
    final request = http.MultipartRequest('POST', _uri())
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['caption'] = caption
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
          contentType: MediaType.parse(mime),
        ),
      );
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(minutes: 3)),
    ).timeout(const Duration(minutes: 3));
    return Reel.fromJson(_decode(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The reels service returned an invalid response.');
    }
    if (response.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Unable to load reels.');
    }
    return body;
  }
}
