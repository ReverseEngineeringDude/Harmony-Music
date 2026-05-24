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
