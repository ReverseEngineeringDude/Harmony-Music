import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';

import '../../../services/recommendation_service.dart';
import '../../../utils/helper.dart';
import '../../player/player_controller.dart';

/// GetX controller that owns the "For You" recommendation list.
///
/// Lifecycle:
///   - [onInit] checks for cold-start and loads initial recommendations.
///   - External callers (PlayerController) call [onSongPlayed], [onSongSkipped],
///     and [onLikeToggled] to refresh after user actions.
class RecommendationController extends GetxController {
  /// The ranked "For You" list shown in the home screen.
  final recommendations = <MediaItem>[].obs;

  /// True while the first load is in progress.
  final isLoading = true.obs;

  /// True when not enough songs have been played to produce meaningful recs.
  final isColdStart = false.obs;

  // Track the song that was "currently playing" so we can measure listen time.
  DateTime? _songStartTime;

  @override
  void onInit() {
    super.onInit();
    _loadRecommendations();
  }

  // ── Public event hooks ───────────────────────────────────────────────────

  /// Should be called by [PlayerController] whenever a new song starts.
  Future<void> onSongStarted(MediaItem song) async {
    _songStartTime = DateTime.now();
    await RecommendationService.recordPlay(song);
    await _loadRecommendations();
  }

  /// Should be called when the user skips (i.e., when a new song starts
  /// *before* the current one finishes, detected by [PlayerController]).
  Future<void> onSongSkipped(MediaItem skippedSong) async {
    final startTime = _songStartTime;
    if (startTime != null) {
      final listenedFor = DateTime.now().difference(startTime);
      await RecommendationService.recordSkip(skippedSong, listenedFor);
      await _loadRecommendations();
    }
    _songStartTime = null;
  }

  /// Should be called by [PlayerController.toggleFavourite] after the like
  /// state changes.
  Future<void> onLikeToggled(String songId, {required bool isLiked}) async {
    await RecommendationService.recordLike(songId, liked: isLiked);
    await _loadRecommendations();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<void> _loadRecommendations() async {
    try {
      final hasHistory = await RecommendationService.hasEnoughHistory();
      if (!hasHistory) {
        isColdStart.value = true;
        isLoading.value = false;
        _loadColdStartFallback();
        return;
      }

      isColdStart.value = false;
      final results = await RecommendationService.getHybridRecommendations();
      recommendations.value = results;
    } catch (e) {
      printERROR('RecommendationController._loadRecommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Cold-start fallback: grab the most recently played songs from the queue.
  void _loadColdStartFallback() {
    try {
      final playerController = Get.find<PlayerController>();
      final queue = playerController.currentQueue.toList();
      if (queue.isNotEmpty) {
        recommendations.value = queue.take(10).toList();
      }
    } catch (_) {
      // Player not yet ready — leave recommendations empty
    }
  }
}
