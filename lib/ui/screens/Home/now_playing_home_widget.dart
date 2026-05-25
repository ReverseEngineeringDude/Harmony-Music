import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../player/player_controller.dart';
import '../../widgets/image_widget.dart';

class NowPlayingHomeWidget extends StatelessWidget {
  const NowPlayingHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      final currentSong = playerController.currentSong.value;
      if (currentSong == null) return const SizedBox.shrink();

      final lyricsStr = (playerController.lyrics['synced'] ?? playerController.lyrics['unsynced'] ?? '').toString().trim();
      final hasLyrics = lyricsStr.isNotEmpty;

      // Extract a short snippet of lyrics if available
      String lyricsSnippet = "No lyrics available";
      if (hasLyrics) {
         // Clean up the timestamps if it's synced [00:00.00]
         lyricsSnippet = lyricsStr
            .replaceAll(RegExp(r'\[.*?\]'), '')
            .trim()
            .split('\n')
            .firstWhere((l) => l.trim().isNotEmpty, orElse: () => "");
      }

      return GestureDetector(
        onTap: () {
            if (GetPlatform.isDesktop) return; // on mobile open panel
            playerController.playerPanelController.open();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ImageWidget(
                  size: 64,
                  song: currentSong,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Now Playing",
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentSong.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasLyrics ? '"$lyricsSnippet"' : (currentSong.artist ?? 'Unknown Artist'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        fontStyle: hasLyrics ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 36,
              ),
            ],
          ),
        ),
      );
    });
  }
}
