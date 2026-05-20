import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';

import '../utils/helper.dart';

/// Thrown when the Gemini API returns a quota / rate-limit error.
/// [retryAfterSeconds] is parsed from the API message when available.
class GeminiQuotaException implements Exception {
  final int retryAfterSeconds;
  const GeminiQuotaException(this.retryAfterSeconds);
  @override
  String toString() => 'GeminiQuotaException(retryAfter: ${retryAfterSeconds}s)';
}

/// Generates lyrics for a song using the Gemini generative AI API.
///
/// Both a plain-text version and a time-synced LRC format version are
/// produced in a single request. The results are cached in the 'lyrics'
/// Hive box (under a `_gemini`-suffixed key) so subsequent lookups are instant.
class GeminiLyricsService {
  /// Fetches (from cache) or generates lyrics for [song] via Gemini AI.
  ///
  /// Returns a map with keys:
  ///   - `"synced"`      → LRC-formatted synced lyrics string (may be empty)
  ///   - `"plainLyrics"` → plain-text lyrics string (may be empty)
  ///
  /// Returns `null` when no API key is set or generation fails.
  static Future<Map<String, dynamic>?> generateLyrics(MediaItem song) async {
    // ── 1. Load API key ──────────────────────────────────────────────────────
    final prefs = Hive.box('AppPrefs');
    final apiKey = (prefs.get('geminiApiKey') as String? ?? '').trim();
    final String modelName = prefs.get('geminiModel') as String? ?? 'gemini-1.5-flash';
    if (apiKey.isEmpty) {
      printINFO('GeminiLyrics: no API key configured, skipping AI generation');
      return null;
    }

    // ── 2. Check lyrics cache ────────────────────────────────────────────────
    final lyricsBox = await Hive.openBox('lyrics');
    final cacheKey = '${song.id}_gemini';
    if (lyricsBox.containsKey(cacheKey)) {
      printINFO('GeminiLyrics: cache hit for "${song.title}"');
      final cached = Map<String, dynamic>.from(lyricsBox.get(cacheKey) as Map);
      await lyricsBox.close();
      return cached;
    }

    // ── 3. Build prompt ───────────────────────────────────────────────────────
    final artist = song.artist?.split(',').first.trim() ?? 'Unknown Artist';
    final title = song.title;
    final durationSec = song.duration?.inSeconds ?? 180;
    final album = song.album ?? '';

    final prompt = '''
You are a professional lyricist. Generate realistic, full song lyrics for:
- Title: "$title"
- Artist: $artist${album.isNotEmpty ? '\n- Album: $album' : ''}
- Duration: approximately $durationSec seconds

Respond with ONLY valid JSON — no markdown fences, no extra text.

Return this exact JSON structure:
{
  "plainLyrics": "<full song lyrics as plain text with newlines as \\n>",
  "syncedLyrics": "<the same lyrics in LRC format, e.g. [00:12.34] Verse line>"
}

Rules for syncedLyrics (LRC format):
- Use [mm:ss.xx] timestamps (e.g. [00:05.00])
- Space lines evenly across $durationSec seconds
- Include blank-text timestamp lines for instrumental gaps: [01:05.00]
- First lyric line starts around [00:05.00]
- Last lyric line ends a few seconds before the total duration

Rules for plainLyrics:
- Include section labels like [Verse 1], [Chorus], [Bridge]
- Separate sections with blank lines (\\n\\n)
- Make it genuine and emotionally fitting for the title and artist style
''';

    // ── 4. Call Gemini API ───────────────────────────────────────────────────
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.85,
          maxOutputTokens: 2048,
          responseMimeType: 'application/json',
        ),
      );

      printINFO('GeminiLyrics: generating lyrics for "$title" by $artist');
      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = (response.text ?? '').trim();

      if (rawText.isEmpty) {
        printERROR('GeminiLyrics: empty response from Gemini');
        await lyricsBox.close();
        return null;
      }

      // Strip accidental markdown fences
      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // ── 5. Parse response ──────────────────────────────────────────────────
      final Map<String, dynamic> parsed =
          json.decode(cleaned) as Map<String, dynamic>;

      final plain = (parsed['plainLyrics'] as String? ?? '').trim();
      final synced = (parsed['syncedLyrics'] as String? ?? '').trim();

      if (plain.isEmpty && synced.isEmpty) {
        printERROR('GeminiLyrics: both plain and synced lyrics are empty');
        await lyricsBox.close();
        return null;
      }

      final lyricsData = <String, dynamic>{
        'synced': synced,
        'plainLyrics': plain,
      };

      // ── 6. Cache and return ────────────────────────────────────────────────
      await lyricsBox.put(cacheKey, lyricsData);
      await lyricsBox.close();

      printINFO('GeminiLyrics: ✓ generated lyrics for "$title"');
      return lyricsData;
    } catch (e) {
      _rethrowIfQuota(e);
      printERROR('GeminiLyrics: generation error → $e');
      try {
        await lyricsBox.close();
      } catch (_) {}
      return null;
    }
  }

  /// Generates LRC-formatted synced lyrics from [plainLyrics] that already
  /// exist, without regenerating the full song text.
  static Future<String?> generateSyncedFromPlain({
    required String title,
    required String artist,
    required String plainLyrics,
    required int durationSec,
  }) async {
    final prefs = Hive.box('AppPrefs');
    final apiKey = (prefs.get('geminiApiKey') as String? ?? '').trim();
    final String modelName = prefs.get('geminiModel') as String? ?? 'gemini-1.5-flash';
    if (apiKey.isEmpty || plainLyrics.isEmpty) return null;

    final prompt = '''
Given the plain lyrics below for "$title" by $artist (total duration: ~$durationSec seconds),
generate LRC time-synced lyrics. Space timestamps evenly across the duration.
First line around [00:05.00], last line a few seconds before $durationSec s.
Use empty-text timestamp lines for instrumental gaps: [01:05.00]
Return ONLY valid JSON, no markdown fences:
{ "syncedLyrics": "<full LRC>" }

Plain lyrics:
$plainLyrics
''';

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 1024,
          responseMimeType: 'application/json',
        ),
      );

      printINFO('GeminiLyrics: generating synced lyrics for "$title"');
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = (response.text ?? '')
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      if (raw.isEmpty) return null;

      final parsed = json.decode(raw) as Map<String, dynamic>;
      final synced = (parsed['syncedLyrics'] as String? ?? '').trim();
      if (synced.isEmpty) return null;

      printINFO('GeminiLyrics: ✓ synced lyrics generated for "$title"');
      return synced;
    } catch (e) {
      _rethrowIfQuota(e);
      printERROR('GeminiLyrics: generateSyncedFromPlain error → $e');
      return null;
    }
  }

  /// Removes the cached Gemini-generated lyrics for [songId] so the next call
  /// to [generateLyrics] will regenerate them from scratch.
  static Future<void> clearCache(String songId) async {
    try {
      final lyricsBox = await Hive.openBox('lyrics');
      await lyricsBox.delete('${songId}_gemini');
      await lyricsBox.close();
      printINFO('GeminiLyrics: cache cleared for $songId');
    } catch (e) {
      printERROR('GeminiLyrics: clearCache error → $e');
    }
  }

  /// Translates [plainLyrics] (and optionally [syncedLyrics]) into [targetLanguage].
  ///
  /// For synced lyrics the timestamps are preserved verbatim; only the lyric
  /// text after each `[mm:ss.xx]` marker is translated.
  static Future<Map<String, dynamic>?> translateLyrics({
    required String plainLyrics,
    required String syncedLyrics,
    required String targetLanguage,
  }) async {
    final prefs = Hive.box('AppPrefs');
    final apiKey = (prefs.get('geminiApiKey') as String? ?? '').trim();
    final String modelName = prefs.get('geminiModel') as String? ?? 'gemini-1.5-flash';
    if (apiKey.isEmpty || plainLyrics.isEmpty) return null;

    final langName = _langCodeToName(targetLanguage);

    final prompt = '''
Translate the following song lyrics into $langName.
Keep all section labels ([Verse 1], [Chorus], etc.) and blank lines as-is.
For the LRC synced lyrics, keep every timestamp like [00:12.34] exactly unchanged — only translate the text that follows each timestamp.
Respond with ONLY valid JSON — no markdown fences:
{
  "plainLyrics": "<translated plain lyrics>",
  "syncedLyrics": "<translated LRC with original timestamps>"
}

Plain lyrics:
$plainLyrics

${syncedLyrics.isNotEmpty ? 'LRC synced lyrics:\n$syncedLyrics' : ''}
''';

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 2048,
          responseMimeType: 'application/json',
        ),
      );

      printINFO('GeminiLyrics: translating lyrics to $langName');
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = (response.text ?? '')
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      if (raw.isEmpty) return null;

      final parsed = json.decode(raw) as Map<String, dynamic>;
      final plain = (parsed['plainLyrics'] as String? ?? '').trim();
      final synced = (parsed['syncedLyrics'] as String? ?? '').trim();

      if (plain.isEmpty) return null;
      printINFO('GeminiLyrics: ✓ translated lyrics to $langName');
      return {'plainLyrics': plain, 'synced': synced};
    } catch (e) {
      _rethrowIfQuota(e);
      printERROR('GeminiLyrics: translateLyrics error → $e');
      return null;
    }
  }

  /// Checks whether [e] is a Gemini quota/rate-limit error.
  /// If so, parses the retry duration and throws [GeminiQuotaException].
  static void _rethrowIfQuota(Object e) {
    final msg = e.toString().toLowerCase();
    // 'generate' contains 'rate', so we must specifically look for 'rate limit'
    if (msg.contains('quota') || msg.contains('rate limit') || msg.contains('429')) {
      // Try to parse "Please retry in 17.842s" from the message
      final match =
          RegExp(r'retry in (\d+(?:\.\d+)?)s').firstMatch(e.toString());
      final seconds = match != null
          ? (double.tryParse(match.group(1) ?? '0') ?? 0).ceil()
          : 0;
      throw GeminiQuotaException(seconds);
    }
  }

  static String _langCodeToName(String code) {
    const map = <String, String>{
      'en': 'English', 'hi': 'Hindi', 'ta': 'Tamil', 'te': 'Telugu',
      'ml': 'Malayalam', 'kn': 'Kannada', 'bn': 'Bengali', 'mr': 'Marathi',
      'gu': 'Gujarati', 'pa': 'Punjabi', 'fr': 'French', 'de': 'German',
      'es': 'Spanish', 'it': 'Italian', 'pt': 'Portuguese', 'ru': 'Russian',
      'ja': 'Japanese', 'ko': 'Korean', 'zh': 'Chinese', 'ar': 'Arabic',
      'tr': 'Turkish', 'pl': 'Polish', 'nl': 'Dutch', 'sv': 'Swedish',
      'fi': 'Finnish', 'nb': 'Norwegian', 'cs': 'Czech', 'sk': 'Slovak',
      'ro': 'Romanian', 'uk': 'Ukrainian', 'id': 'Indonesian', 'vi': 'Vietnamese',
      'zh-CN': 'Chinese (Simplified)', 'zh-TW': 'Chinese (Traditional)',
    };
    return map[code] ?? map[code.split('_').first] ?? map[code.split('-').first] ?? code;
  }
}
