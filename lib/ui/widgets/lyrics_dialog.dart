import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/components/lyrics_switch.dart';
import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import '/ui/widgets/common_dialog_widget.dart';

class LyricsDialog extends StatelessWidget {
  const LyricsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    return CommonDialog(
      maxWidth: 700,
      child: Column(
        children: [
          // ── Header: mode switch + AI/Translate chips ─────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LyricsSwitch(),
                Obx(() {
                  final hasLyrics =
                      (pc.lyrics['plainLyrics'] ?? '').isNotEmpty &&
                          pc.lyrics['plainLyrics'] != 'NA';
                  if (!hasLyrics) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      // Translate chip
                      _DialogChip(
                        icon: pc.isLyricsTranslating.isTrue
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5),
                              )
                            : Icon(
                                pc.isLyricsTranslated.isTrue
                                    ? Icons.check_circle_outline
                                    : Icons.translate,
                                size: 14,
                              ),
                        label: pc.isLyricsTranslated.isTrue
                            ? 'lyricsTranslated'.tr
                            : 'translateLyrics'.tr,
                        onTap: pc.isLyricsTranslating.isTrue
                            ? null
                            : pc.translateLyricsWithAi,
                        color: pc.isLyricsTranslated.isTrue
                            ? Colors.teal
                            : Theme.of(context).colorScheme.secondaryContainer,
                        labelColor: pc.isLyricsTranslated.isTrue
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                      ),
                      // AI chip + retry (only when AI-generated)
                      if (pc.isLyricsAiGenerated.isTrue) ...[
                        const SizedBox(width: 6),
                        _DialogChip(
                          icon: const Icon(Icons.auto_awesome, size: 14,
                              color: Colors.white),
                          label: 'AI',
                          onTap: null,
                          color: Colors.deepPurple,
                          labelColor: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'retryAiLyrics'.tr,
                          child: InkWell(
                            onTap: pc.retryAiLyrics,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh_rounded,
                                  size: 14, color: Colors.deepPurple),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          // ── Lyrics content ───────────────────────────────────────────────
          const Expanded(
            child: LyricsWidget(
                padding: EdgeInsets.symmetric(vertical: 40)),
          ),
        ],
      ),
    );
  }
}

class _DialogChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color labelColor;

  const _DialogChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
