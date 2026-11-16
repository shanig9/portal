import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<Directory> _directory() async {
  final root = await getApplicationDocumentsDirectory();
  return Directory('${root.path}/reels').create(recursive: true);
}

// Each reel has its own metadata file, so an interrupted save cannot damage
// the rest of the library. Paths are rebuilt to survive sandbox relocation.
Future<List<Map<String, dynamic>>> readLocalReels() async {
  final directory = await _directory();
  final items = <Map<String, dynamic>>[];
  await for (final entry in directory.list()) {
    if (entry is! File || !entry.path.endsWith('.json')) continue;
    try {
      final data =
          jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
      final media = File('${directory.path}/${data['filename']}');
      if (await media.exists()) {
        items.add({...data, 'url': media.uri.toString()});
      }
    } on FormatException {
      continue;
    }
  }
  items.sort((a, b) => (b['id'] as String).compareTo(a['id'] as String));
  return items;
}

Future<String> saveLocalReel(
  Uint8List bytes,
  String extension,
  Map<String, dynamic> metadata,
) async {
  final directory = await _directory();
  final filename = '${metadata['id']}.$extension';
  final media = File('${directory.path}/$filename');
  await media.writeAsBytes(bytes, flush: true);
  try {
    final temporary = File('${directory.path}/${metadata['id']}.tmp');
    await temporary.writeAsString(
      jsonEncode({...metadata, 'filename': filename}),
      flush: true,
    );
    await temporary.rename('${directory.path}/${metadata['id']}.json');
  } catch (_) {
    await media.delete();
    rethrow;
  }
  return media.uri.toString();
}

VideoPlayerController localReelPlayer(String path) =>
    VideoPlayerController.file(File.fromUri(Uri.parse(path)));
