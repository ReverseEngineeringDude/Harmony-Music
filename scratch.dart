import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() async {
  Hive.init('./.hive_data'); // Or wherever Hive is. But this is a Flutter app.
  print('Done');
}
