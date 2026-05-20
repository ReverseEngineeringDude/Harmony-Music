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
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ));
    final dur = song.duration?.inSeconds ?? durInSec;

    // ── Primary: exact match by artist / track / album / duration ─────────
    final exactUrl =
        'https://lrclib.net/api/get?artist_name=${Uri.encodeQueryComponent(song.artist?.split(",").first.trim() ?? "")}'
        '&track_name=${Uri.encodeQueryComponent(song.title)}'
        '&album_name=${Uri.encodeQueryComponent(song.album ?? "")}'
        '&duration=$dur';
    try {
      final response = (await dio.get(exactUrl)).data;
      if (response is Map && response["syncedLyrics"] != null) {
        printINFO("Lyrics: exact synced match found");
        final lyricsData = {
          "synced": response["syncedLyrics"],
          "plainLyrics": response["plainLyrics"] ?? ""
        };
        await lyricsBox.put(song.id, lyricsData);
        await lyricsBox.close();
        return lyricsData;
      }
    } on DioException catch (e) {
      // 404 TrackNotFound is expected — fuzzy search will handle it
      if (e.response?.statusCode != 404) {
        printERROR("Lyrics exact lookup error: ${e.response}");
      }
    }

    // ── Secondary: fuzzy search by track name ─────────────────────────────
    final searchUrl =
        'https://lrclib.net/api/search?track_name=${Uri.encodeQueryComponent(song.title)}'
        '&artist_name=${Uri.encodeQueryComponent(song.artist?.split(",").first.trim() ?? "")}';
    try {
      final results = (await dio.get(searchUrl)).data;
      if (results is List && results.isNotEmpty) {
        // Prefer a result with synced lyrics whose duration is close (±10 s)
        Map<String, dynamic>? bestSynced;
        Map<String, dynamic>? bestPlain;

        for (final item in results) {
          if (item is! Map) continue;
          final itemDur = (item['duration'] as num?)?.toInt() ?? 0;
          final durOk = (itemDur - dur).abs() <= 10;

          if (item['syncedLyrics'] != null && durOk && bestSynced == null) {
            bestSynced = Map<String, dynamic>.from(item);
          }
          if (item['plainLyrics'] != null && durOk && bestPlain == null) {
            bestPlain = Map<String, dynamic>.from(item);
          }
          if (bestSynced != null) break;
        }

        final best = bestSynced ?? bestPlain;
        if (best != null) {
          printINFO("Lyrics: fuzzy search match found (synced=${best['syncedLyrics'] != null})");
          final lyricsData = {
            "synced": best["syncedLyrics"] ?? "",
            "plainLyrics": best["plainLyrics"] ?? ""
          };
          await lyricsBox.put(song.id, lyricsData);
          await lyricsBox.close();
          return lyricsData;
        }
      }
    } on DioException catch (e) {
      printERROR("Lyrics search error: ${e.response}");
    }

    await lyricsBox.close();
    return null; // caller will fall back to YouTube Music plain-text lyrics
  }
}
