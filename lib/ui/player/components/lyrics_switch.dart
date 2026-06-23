import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/utils/theme_controller.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../player_controller.dart';

class LyricsSwitch extends StatelessWidget {
  const LyricsSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    return Obx(
      () => playerController.showLyricsflag.value
          ? LayoutBuilder(
              builder: (context, constraints) {
                // Determine the available width for each pill (subtracting a small margin for borders/dividers)
                double availableWidth = constraints.maxWidth;
                double pillWidth = (availableWidth / 2) - 2.0;
                
                // Safety clamp to prevent negative widths on extremely small screens
                if (pillWidth < 0) pillWidth = 10.0;
                
                return ToggleSwitch(
                  minWidth: pillWidth,
                  cornerRadius: 20.0,
                  activeBgColors: [
                    [Colors.white.withValues(alpha: 0.25)],
                    [Colors.white.withValues(alpha: 0.25)]
                  ],
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.transparent, // Removed the background container box
                  dividerColor: Colors.transparent, // Removed the divider line
                  inactiveFgColor: Colors.white70,
                  initialLabelIndex: playerController.lyricsMode.value,
                  totalSwitches: 2,
                  labels: ['synced'.tr, 'plain'.tr],
                  radiusStyle: true,
                  onToggle: (index) {
                    if (index != null && index == playerController.lyricsMode.value) {
                      playerController.showLyricsflag.value = false;
                    } else {
                      playerController.changeLyricsMode(index);
                    }
                  },
                );
              }
            )
          : const SizedBox.shrink(),
    );
  }
}
