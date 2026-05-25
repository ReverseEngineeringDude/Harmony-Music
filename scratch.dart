import 'package:harmonymusic/services/transliteration_service.dart';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://aksharamukha-plugin.appspot.com/api/public?source=IAST&target=Malayalam&text=Anbe Sivam');
  final response = await http.get(url);
  print(response.body);
}
