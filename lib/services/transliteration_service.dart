import 'package:dio/dio.dart';

class TransliterationService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static final Map<String, RegExp> _scriptRanges = {
    'Devanagari': RegExp(r'[\u0900-\u097F]'),
    'Bengali': RegExp(r'[\u0980-\u09FF]'),
    'Gurmukhi': RegExp(r'[\u0A00-\u0A7F]'),
    'Gujarati': RegExp(r'[\u0A80-\u0AFF]'),
    'Odia': RegExp(r'[\u0B00-\u0B7F]'),
    'Tamil': RegExp(r'[\u0B80-\u0BFF]'),
    'Telugu': RegExp(r'[\u0C00-\u0C7F]'),
    'Kannada': RegExp(r'[\u0C80-\u0CFF]'),
    'Malayalam': RegExp(r'[\u0D00-\u0D7F]'),
    'IAST': RegExp(r'[a-zA-Z]'),
  };

  /// Detects the predominant script in the given text.
  static String _detectScript(String text) {
    int maxCount = 0;
    String detectedScript = 'Unknown';

    for (var entry in _scriptRanges.entries) {
      final matchCount = entry.value.allMatches(text).length;
      if (matchCount > maxCount) {
        maxCount = matchCount;
        detectedScript = entry.key;
      }
    }
    return detectedScript;
  }

  /// Transliterates text from its auto-detected Indic script to the target script.
  /// Skips conversion if the script is not an Indic script or if it's already the target.
  static Future<String> transliterate(String text, String targetScript) async {
    final sourceScript = _detectScript(text);

    if (sourceScript == 'Unknown' || sourceScript == targetScript) {
      return text;
    }

    try {
      final url = 'https://aksharamukha-plugin.appspot.com/api/public';
      final response = await _dio.get(url, queryParameters: {
        'source': sourceScript,
        'target': targetScript,
        'text': text,
      });

      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
    } catch (e) {
      print('Transliteration failed: $e');
    }
    return text;
  }

  /// Parses an LRC string, transliterates the text portions, and preserves timestamps.
  static Future<String> transliterateLrc(String lrc, String targetScript) async {
    final sourceScript = _detectScript(lrc);
    if (sourceScript == 'Unknown' || sourceScript == targetScript) {
      return lrc;
    }

    // Split LRC into lines
    final lines = lrc.split('\n');
    final Map<String, String> lineMap = {};
    
    // We want to send all text in one batch to save API calls
    final timestampRegex = RegExp(r'^(\[[0-9:\.]+\])+(.*)$');
    
    List<String> plainLines = [];
    List<String> timestamps = [];

    for (var line in lines) {
      final match = timestampRegex.firstMatch(line.trim());
      if (match != null) {
        timestamps.add(match.group(1) ?? '');
        plainLines.add(match.group(2)?.trim() ?? '');
      } else {
        timestamps.add('');
        plainLines.add(line.trim());
      }
    }

    // Join with a unique delimiter for batch translation
    final batchText = plainLines.join('\n');
    
    final transliteratedBatch = await transliterate(batchText, targetScript);
    final transliteratedLines = transliteratedBatch.split('\n');

    // Stitch back together
    final buffer = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      if (i < transliteratedLines.length) {
        buffer.writeln('${timestamps[i]}${transliteratedLines[i]}');
      } else {
        buffer.writeln(lines[i]);
      }
    }

    return buffer.toString().trim();
  }
}
