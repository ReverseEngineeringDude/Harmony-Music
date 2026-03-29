import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../player/player_controller.dart';
import 'recommendation_controller.dart';

/// "For You" horizontal scroll strip shown at the top of the Home tab.
///
/// Invisible during cold start or while loading. Automatically refreshes
/// as the user plays, skips, and likes songs.
class ForYouWidget extends StatelessWidget {
  const ForYouWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recController = Get.find<RecommendationController>();
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final recs = recController.recommendations;

      // Hide when loading or no data
      if (recController.isLoading.isTrue || recs.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 10),
            child: Text(
              'For You',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 4),
              scrollDirection: Axis.horizontal,
              itemCount: recs.length,
              itemBuilder: (context, index) {
                final song = recs[index];
                return _ForYouCard(
                  song: song,
                  onTap: () => playerController.playPlayListSong(
                    recs,
                    index,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({required this.song, required this.onTap});

  final MediaItem song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: song.artUri != null
                  ? Image.network(
                      song.artUri.toString(),
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
            const SizedBox(height: 6),
            // Song title
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            // Artist
            Text(
              song.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.65),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.music_note, size: 40),
      );
}
