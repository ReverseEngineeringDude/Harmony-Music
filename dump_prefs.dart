import 'package:hive/hive.dart';
import 'dart:io';

void main() async {
  Hive.init('/home/red/.local/share/com.example.harmonymusic/db');
  
  final prefs = await Hive.openBox('AppPrefs');
  print('Keys in AppPrefs:');
  for (final key in prefs.keys) {
    print('$key : ${prefs.get(key)}');
  }
}
