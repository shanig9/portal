import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart';

import 'reel_storage.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';

class ReelsApiException implements Exception {
  ReelsApiException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}

class Reel {
  Reel.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      url = json['url'] as String,
      type = json['type'] as String,
      caption = json['caption'] as String,
      author = json['author'] as String,
      remoteId = json['remoteId'] as String?,
      uploadError = json['uploadError'] as String?,
      pending = json['pending'] == true,
      needsAttention = json['needsAttention'] == true;
  final String id, url, type, caption, author;
  final String? remoteId;
  final String? uploadError;
  final bool pending;
  final bool needsAttention;
}

class ReelsPage {
  ReelsPage(this.items, this.nextCursor);
  final List<Reel> items;
  final String? nextCursor;
}

class ReelsService {
  static final _syncing = <String>{};
  Future<void> syncPending() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_syncing.add(user.uid)) return;
    try {
      for (final item in await readLocalReels()) {
        if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
        if (item['pending'] != true ||
            item['ownerId'] != user.uid ||
            (item['needsAttention'] == true && item['uploadError'] != null)) {
          continue;
        }
        try {
          final remote = await _upload(
            user,
            item['id'] as String,
            await readReelBytes(item['url'] as String),
            item['filename'] as String,
            item['caption'] as String,
          );
          await markReelSynced({
            ...item,
            'needsAttention': false,
            'uploadError': null,
          }, remote.id);
        } catch (error) {
          await updateReelMetadata({
            ...item,
            'needsAttention':
                error is ReelsApiException &&
                [413, 415, 422].contains(error.status),
            'uploadError': errorMessage(error),
          });
        }
      }
    } finally {
      _syncing.remove(user.uid);
    }
  }

  Future<List<Reel>> deviceReels() async {
    final local = (await readLocalReels())
        .where(
          (item) =>
              Firebase.apps.isNotEmpty &&
              item['ownerId'] == FirebaseAuth.instance.currentUser?.uid,
        )
        .map((item) => Reel.fromJson(item))
        .toList();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('assets/reels/') && path.endsWith('.mp4'),
            )
            .toList()
          ..sort();
    return [
      ...local,
      for (final path in assets)
        Reel.fromJson({
          'id': path,
          'url': path,
          'type': 'video',
          'caption': 'Career Connect',
          'author': 'Career Connect',
        }),
    ];
  }

  Future<Reel> saveOnDevice(
    Uint8List bytes,
    String name,
    String caption,
  ) async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in before adding a reel.');
    }
    final extension = name.split('.').last.toLowerCase();
    if (!['mp4', 'mov', 'webm'].contains(extension)) {
      throw Exception('Choose an MP4, MOV or WebM video.');
    }
    if (bytes.isEmpty || bytes.length > 50 * 1024 * 1024) {
      throw Exception('Choose a video of up to 50 MB.');
    }
    final data = <String, dynamic>{
      'pending': true,
      'ownerId': FirebaseAuth.instance.currentUser!.uid,
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'type': 'video',
      'caption': caption,
      'author': 'You · On this device',
    };
    final url = await saveLocalReel(bytes, extension, data);
    return Reel.fromJson({...data, 'url': url});
  }

  static String get baseUrl => ApiConfig.baseUrl;

  static String errorMessage(Object error) {
    if (error is TimeoutException || error is http.ClientException) {
      return 'Cannot reach the reels server. Check your connection and try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Uri _uri({String path = '', Map<String, String>? query}) {
    if (baseUrl.isEmpty) {
      throw Exception(
        'Reels are unavailable because the app has no server connection configured.',
      );
    }
    return Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r"/$"), "")}/api/reels$path',
    ).replace(queryParameters: query);
  }

  Future<ReelsPage> list({String? cursor}) async {
    final response = await http
        .get(_uri(query: {'limit': '10', 'cursor': ?cursor}))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    return ReelsPage(
      (body['items'] as List).map((item) => Reel.fromJson(item)).toList(),
      body['nextCursor'] as String?,
    );
  }

  Future<Reel> _upload(
    User user,
    String uploadId,
    Uint8List bytes,
    String name,
    String caption,
  ) async {
    final token = await user.getIdToken();
    final mime = {
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
    }[name.split('.').last.toLowerCase()];
    if (mime == null) throw ReelsApiException(415, 'Unsupported video type.');
    final client = http.Client();
    try {
      final ticket = await _post(client, '/upload-ticket', token, {
        'uploadId': uploadId,
      });
      if (ticket['reel'] case final Map<String, dynamic> published) {
        return Reel.fromJson(published);
      }
      final url = Uri.parse(ticket['url'] as String);
      if (url.scheme != 'https' || url.host != 'api.cloudinary.com') {
        throw Exception('The reels server returned an invalid upload URL.');
      }
      final request = http.MultipartRequest('POST', url)
        ..fields.addAll(
          (ticket['fields'] as Map<String, dynamic>).map(
            (name, value) => MapEntry(name, value.toString()),
          ),
        )
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: name,
            contentType: MediaType.parse(mime),
          ),
        );
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(minutes: 3)),
      ).timeout(const Duration(minutes: 3));
      if (response.statusCode == 413) {
        throw ReelsApiException(413, 'Cloudinary rejected the video size.');
      }
      // A retry may find the same asset already uploaded, with overwrite off.
      if (response.statusCode >= 400 && response.statusCode != 409) {
        throw ReelsApiException(
          502,
          'Cloudinary rejected the video upload. Try again.',
        );
      }
      return Reel.fromJson(
        await _post(client, '/complete-upload', token, {
          'uploadId': uploadId,
          'caption': caption,
        }),
      );
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _post(
    http.Client client,
    String path,
    String? token,
    Map<String, String> body,
  ) async => _decode(
    await client
        .post(
          _uri(path: path),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30)),
  );

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 413) {
      throw ReelsApiException(
        413,
        'This video is too large to share. Choose a smaller video.',
      );
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode == 404) {
        throw Exception(
          'This server does not have the reels API. Update the Career Connect server.',
        );
      }
      throw Exception('The reels service returned an invalid response.');
    }
    if (response.statusCode >= 400) {
      throw ReelsApiException(
        response.statusCode,
        body['error'] as String? ?? 'Unable to load reels.',
      );
    }
    return body;
  }
}
