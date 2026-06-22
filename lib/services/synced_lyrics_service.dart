import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:harmonymusic/utils/helper.dart';
import 'package:hive/hive.dart';

class SyncedLyricsService {
  static Future<Map<String, dynamic>?> getSyncedLyrics(
      MediaItem song, int durInSec) async {
    final lyricsBox = await Hive.openBox("lyrics");
    // check if lyrics available in local database
    if (lyricsBox.containsKey(song.id)) {
      return Map<String, dynamic>.from(await lyricsBox.get(song.id));
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'HarmonyMusic/1.0 (https://github.com/ReverseEngineeringDude/Harmony-Music)'
      },
    ));
    final dur = song.duration?.inSeconds ?? durInSec;

    String actualArtist = song.artist?.split(",").first.trim() ?? "";
    if (actualArtist.toLowerCase() == "song" || actualArtist.toLowerCase() == "video") {
      actualArtist = song.artist?.split(",").skip(1).firstOrNull?.trim() ?? "";
    }

    // ── Primary: exact match by artist / track / album / duration ─────────
    final exactUrl =
        'https://lrclib.net/api/get?artist_name=${Uri.encodeQueryComponent(actualArtist)}'
        '&track_name=${Uri.encodeQueryComponent(song.title)}'
        '&album_name=${Uri.encodeQueryComponent(song.album ?? "")}'
        '&duration=$dur';
    try {
      final response = (await dio.get(exactUrl)).data;
      print('exactUrl: $exactUrl');
      if (response is Map && response["syncedLyrics"] != null) {
        printINFO("Lyrics: exact synced match found");
        final lyricsData = {
          "synced": response["syncedLyrics"],
          "plainLyrics": response["plainLyrics"] ?? ""
        };
        await lyricsBox.put(song.id, lyricsData);
        return lyricsData;
      }
    } on DioException catch (e) {
      // 404 TrackNotFound is expected — fuzzy search will handle it
      if (e.response?.statusCode != 404) {
        printERROR("Lyrics exact lookup error: ${e.response ?? e.message}");
      }
    }

    // ── Secondary: fuzzy search by track name ─────────────────────────────
    final searchUrl =
        'https://lrclib.net/api/search?track_name=${Uri.encodeQueryComponent(song.title)}'
        '&artist_name=${Uri.encodeQueryComponent(actualArtist)}';
    try {
      final results = (await dio.get(searchUrl)).data;
      print('searchUrl: $searchUrl');
      if (results is List && results.isNotEmpty) {
        // Prefer a result with synced lyrics whose duration is close (±10 s)
        Map<String, dynamic>? bestSynced;
        Map<String, dynamic>? bestPlain;
        Map<String, dynamic>? fallbackSynced;
        Map<String, dynamic>? fallbackPlain;

        for (final item in results) {
          if (item is! Map) continue;
          final itemDur = (item['duration'] as num?)?.toInt() ?? 0;
          // allow 15 seconds tolerance for "best" match
          final durOk = dur == 0 || (itemDur - dur).abs() <= 15;

          if (item['syncedLyrics'] != null) {
            fallbackSynced ??= Map<String, dynamic>.from(item);
            if (durOk && bestSynced == null) bestSynced = Map<String, dynamic>.from(item);
          }
          if (item['plainLyrics'] != null) {
            fallbackPlain ??= Map<String, dynamic>.from(item);
            if (durOk && bestPlain == null) bestPlain = Map<String, dynamic>.from(item);
          }
          if (bestSynced != null) break;
        }

        final best = bestSynced ?? fallbackSynced ?? bestPlain ?? fallbackPlain;
        if (best != null) {
          printINFO("Lyrics: fuzzy search match found (synced=${best['syncedLyrics'] != null})");
          final lyricsData = {
            "synced": best["syncedLyrics"] ?? "",
            "plainLyrics": best["plainLyrics"] ?? ""
          };
          await lyricsBox.put(song.id, lyricsData);
          return lyricsData;
        }
      }
    } on DioException catch (e) {
      printERROR("Lyrics search error: ${e.response ?? e.message}");
    }

    return null; // caller will fall back to YouTube Music plain-text lyrics
  }
}
