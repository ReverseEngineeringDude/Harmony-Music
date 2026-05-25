import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/components/lyrics_switch.dart';
import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import '/ui/widgets/common_dialog_widget.dart';
import '../screens/Settings/settings_screen_controller.dart';

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
                  final hasLyrics = (pc.lyrics['plainLyrics'] ?? '').isNotEmpty &&
                      pc.lyrics['plainLyrics'] != 'NA';
                  if (!hasLyrics || Get.find<SettingsScreenController>().isTransliterationEnabled.isFalse) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _DialogChip(
                      icon: pc.isLyricsTransliterating.isTrue
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : Icon(
                              pc.isLyricsTransliterated.isTrue
                                  ? Icons.spellcheck
                                  : Icons.translate,
                              size: 14,
                            ),
                      label: pc.isLyricsTransliterated.isTrue
                          ? 'Transliterated'
                          : 'Transliterate',
                      onTap: pc.isLyricsTransliterating.isTrue
                          ? null
                          : pc.transliterateLyrics,
                      color: pc.isLyricsTransliterated.isTrue
                          ? Colors.teal
                          : Theme.of(context).colorScheme.secondaryContainer,
                      labelColor: pc.isLyricsTransliterated.isTrue
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
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
