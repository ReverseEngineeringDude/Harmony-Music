import 'package:hive/hive.dart';


/// Behavior data tracked per song for offline recommendations.
///
/// Stored in Hive box "songStats". The [score] field is a cached value
/// recomputed whenever behavior data changes, so reads are always O(1).
@HiveType(typeId: 10)
class SongStats extends HiveObject {
  @HiveField(0)
  final String songId;

  @HiveField(1)
  String title;

  @HiveField(2)
  String artist;

  @HiveField(3)
  String artUri;

  /// List of artist browse IDs (may be empty for songs without IDs).
  @HiveField(4)
  List<String> artistIds;

  // ── Behavior counters ────────────────────────────────────────────────────

  @HiveField(5)
  int playCount;

  @HiveField(6)
  int skipCount;

  /// Whether the user has liked/favorited this song.
  @HiveField(7)
  bool isLiked;

  /// Cumulative seconds actually listened to (used for listen-ratio scoring).
  @HiveField(8)
  int listenedSeconds;

  @HiveField(9)
  DateTime lastPlayedAt;

  /// Cached composite score. Updated every time behavior changes.
  @HiveField(10)
  double score;

  SongStats({
    required this.songId,
    required this.title,
    required this.artist,
    required this.artUri,
    required this.artistIds,
    this.playCount = 0,
    this.skipCount = 0,
    this.isLiked = false,
    this.listenedSeconds = 0,
    DateTime? lastPlayedAt,
    this.score = 0.0,
  }) : lastPlayedAt = lastPlayedAt ?? DateTime.now();
}
