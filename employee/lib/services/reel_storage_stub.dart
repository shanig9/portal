import 'dart:typed_data';

import 'package:video_player/video_player.dart';

Future<List<Map<String, dynamic>>> readLocalReels() async => [];
Future<String> saveLocalReel(
  Uint8List bytes,
  String extension,
  Map<String, dynamic> metadata,
) async {
  throw Exception('Saving reels on this device requires the mobile app.');
}

VideoPlayerController localReelPlayer(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));
