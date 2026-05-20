import 'package:flutter_test/flutter_test.dart';
import 'package:harmonymusic/services/music_service.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  test('Search Line without hook', () async {
    Hive.init(Directory.current.path);
    await Hive.openBox('AppPrefs');
    final musicService = MusicServices();
    await musicService.init();
    
    final res = await musicService.search("Line without hook");
    print("Res keys: ${res.keys}");
    if (res['Songs'] != null) {
      print("Songs count: ${res['Songs'].length}");
    } else {
      print("Songs is null");
    }
  });
}
