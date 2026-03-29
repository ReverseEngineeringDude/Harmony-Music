import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';

import '../models/song_stats.dart';
import '../utils/helper.dart';

/// Core offline recommendation service.
///
/// Architecture:
///   1. Behavior events (play / skip / like) are recorded into the Hive
///      "songStats" box and immediately recompute the cached [SongStats.score].
///   2. [getHybridRecommendations] runs a two-pass ranking in a Dart isolate:
///      - scored pass  : rank all known songs by their score
///      - similarity   : find songs sharing an artist or genre with the top seed
///   3. Results are returned as a flat ranked list of [MediaItem].
///
/// All Hive I/O stays on the calling isolate; only the ranking computation
/// is off-loaded to avoid jank during playback.
class RecommendationService {
  static const _boxName = 'songStats';

  // ── Scoring weights ──────────────────────────────────────────────────────
  static const double _wPlay = 10.0;
  static const double _wSkip = -8.0;
  static const double _wLike = 50.0;
  static const double _wListen = 20.0; // applied to listen-ratio 0.0–1.0
  static const double _wRecency = 30.0; // max recency bonus (full decay = 0)
  static const int _recencyHalfLifeDays = 14; // score halves every 14 days

  // ── Public API ───────────────────────────────────────────────────────────

  /// Records a new play event and updates the song's score.
  ///
  /// Call this when a new [MediaItem] starts playing.
  static Future<void> recordPlay(MediaItem song) async {
    final box = await _openBox();
    try {
      final stats = _getOrCreate(box, song);
      stats.playCount++;
      stats.lastPlayedAt = DateTime.now();
      stats.score = _computeScore(stats);
      await stats.save();
    } finally {
      await box.close();
    }
  }

  /// Records a skip event.
  ///
  /// [listenedFor] is how long the user listened before skipping.
  /// If the song was listened to less than 40% of its duration, a skip
  /// penalty is applied. Partial listens beyond 40% are rewarded.
  static Future<void> recordSkip(
      MediaItem song, Duration listenedFor) async {
    final totalSecs = song.duration?.inSeconds ?? 0;
    if (totalSecs == 0) return;

    final ratio = listenedFor.inSeconds / totalSecs;
    final box = await _openBox();
    try {
      final stats = _getOrCreate(box, song);
      stats.listenedSeconds += listenedFor.inSeconds;

      // Only penalise skips that happen early in the song
      if (ratio < 0.40) {
        stats.skipCount++;
      }

      stats.score = _computeScore(stats);
      await stats.save();
    } finally {
      await box.close();
    }
  }

  /// Toggles the like status and recomputes the score.
  static Future<void> recordLike(String songId, {required bool liked}) async {
    final box = await _openBox();
    try {
      final stats = box.get(songId) as SongStats?;
      if (stats == null) return; // song hasn't been played yet
      stats.isLiked = liked;
      stats.score = _computeScore(stats);
      await stats.save();
    } finally {
      await box.close();
    }
  }

  /// Returns top-scored songs as [MediaItem] objects.
  ///
  /// Falls back to an empty list on error (never throws).
  static Future<List<MediaItem>> getRecommendedSongs({int limit = 20}) async {
    try {
      final box = await _openBox();
      try {
        final allStats = box.values.cast<SongStats>().toList();
        if (allStats.isEmpty) return [];

        // Sort inline — HiveObjects can't cross isolate boundaries because
        // they contain internal async Hive state (_Future, ReadWriteSync).
        // O(n log n) sorting is fast enough for any realistic music library.
        allStats.sort((a, b) => b.score.compareTo(a.score));
        return allStats.take(limit).map(_toMediaItem).toList();
      } finally {
        await box.close();
      }
    } catch (e) {
      printERROR('RecommendationService.getRecommendedSongs: $e');
      return [];
    }
  }

  /// Returns songs similar to [seed] (shared artist or similar artist names).
  ///
  /// Similarity is determined by artist ID overlap first; if no IDs are present
  /// it falls back to fuzzy artist-name matching.
  static Future<List<MediaItem>> getSimilarSongs(
      MediaItem seed, {
        int limit = 10,
      }) async {
    try {
      final box = await _openBox();
      try {
        final allStats = box.values.cast<SongStats>().toList();
        if (allStats.isEmpty) return [];

        final seedArtistIds =
            (seed.extras?['artists'] as List? ?? [])
                .map((a) => a['id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();

        final seedArtistName = seed.artist?.toLowerCase() ?? '';

        final similar = allStats
            .where((s) => s.songId != seed.id) // exclude the seed itself
            .where((s) {
          // Artist-ID match (precise)
          if (seedArtistIds.isNotEmpty) {
            return s.artistIds.any((id) => seedArtistIds.contains(id));
          }
          // Fallback: fuzzy artist name match
          return s.artist.toLowerCase().contains(seedArtistName) ||
              seedArtistName.contains(s.artist.toLowerCase());
        })
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        return similar.take(limit).map(_toMediaItem).toList();
      } finally {
        await box.close();
      }
    } catch (e) {
      printERROR('RecommendationService.getSimilarSongs: $e');
      return [];
    }
  }

  /// The primary entry point for the "For You" section.
  ///
  /// Returns a hybrid list:
  ///   - Top-scored songs (60% of the list)
  ///   - Artist-similar songs from the top seed (40% of the list)
  ///
  /// De-duplicates by song ID before returning.
  static Future<List<MediaItem>> getHybridRecommendations({
    int limit = 20,
  }) async {
    try {
      final scored = await getRecommendedSongs(limit: limit);
      if (scored.isEmpty) return [];

      // Use the top song as the similarity seed
      final seed = scored.first;
      final similar =
      await getSimilarSongs(seed, limit: (limit * 0.4).ceil());

      // Merge: scored (primary) then similar (fill remaining slots), no dupes
      final seen = <String>{};
      final merged = <MediaItem>[];

      for (final item in [...scored, ...similar]) {
        if (seen.add(item.id)) merged.add(item);
        if (merged.length >= limit) break;
      }

      return merged;
    } catch (e) {
      printERROR('RecommendationService.getHybridRecommendations: $e');
      return [];
    }
  }

  /// Returns true when the user has enough history for meaningful recs.
  ///
  /// Used for cold-start detection.
  static Future<bool> hasEnoughHistory({int minSongs = 3}) async {
    final box = await _openBox();
    try {
      return box.length >= minSongs;
    } finally {
      await box.close();
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  static Future<Box> _openBox() => Hive.openBox(_boxName);

  /// Fetches existing [SongStats] or creates a new entry for [song].
  static SongStats _getOrCreate(Box box, MediaItem song) {
    final existing = box.get(song.id) as SongStats?;
    if (existing != null) return existing;

    final artistIds = (song.extras?['artists'] as List? ?? [])
        .map((a) => a['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final stats = SongStats(
      songId: song.id,
      title: song.title,
      artist: song.artist ?? '',
      artUri: song.artUri?.toString() ?? '',
      artistIds: artistIds,
    );
    box.put(song.id, stats);
    return stats;
  }

  // ── Scoring formula  ─────────────────────────────────────────────────────

  /// Computes a composite score from the accumulated behavior data.
  ///
  /// Formula (all weights are tunable via `_w*` constants):
  /// ```
  /// score = playCount × wPlay
  ///       + skipCount × wSkip          (negative weight = penalty)
  ///       + (isLiked ? wLike : 0)
  ///       + listenRatio × wListen
  ///       + recencyBoost               (exponential decay by days since play)
  /// ```
  static double _computeScore(SongStats s) {
    // Listen ratio: clamp to [0, 1] — avoid division by zero
    final totalExpected =
        max(s.playCount * 180, 1); // assume avg 3 min song = 180 s
    final listenRatio = (s.listenedSeconds / totalExpected).clamp(0.0, 1.0);

    // Recency bonus using exponential decay
    final daysSincePlay = DateTime.now()
        .difference(s.lastPlayedAt)
        .inHours /
        24.0;
    final recencyBoost =
        _wRecency * exp(-daysSincePlay * ln2 / _recencyHalfLifeDays);

    return (s.playCount * _wPlay) +
        (s.skipCount * _wSkip) +
        (s.isLiked ? _wLike : 0.0) +
        (listenRatio * _wListen) +
        recencyBoost;
  }

  /// Converts a [SongStats] record back into a [MediaItem] for playback.
  static MediaItem _toMediaItem(SongStats s) {
    return MediaItem(
      id: s.songId,
      title: s.title,
      artist: s.artist,
      artUri: Uri.tryParse(s.artUri),
      extras: <String, dynamic>{}, // mutable — audio handler writes 'url' here
    );
  }

  /// Convenience constant — avoids importing `dart:math` in callers.
  static const double ln2 = 0.6931471805599453;
}
