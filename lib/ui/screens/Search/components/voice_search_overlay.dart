import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../search_screen_controller.dart';

class VoiceSearchOverlay extends StatefulWidget {
  const VoiceSearchOverlay({super.key});

  @override
  State<VoiceSearchOverlay> createState() => _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends State<VoiceSearchOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SearchScreenController>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          controller.stopListening();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {}, // absorb taps inside the card
            child: Container(
              width: min(MediaQuery.of(context).size.width * 0.85, 380),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    "Listening...",
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tap anywhere outside to cancel",
                    style: theme.textTheme.bodySmall!
                        .copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 30),

                  // Animated mic ring
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 38,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sound wave bars
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return _SoundWave(
                        progress: _waveController.value,
                        color: primary,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Recognized text
                  Obx(() {
                    final text = controller.recognizedText.value;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: text.isEmpty
                          ? Text(
                              "Speak now...",
                              key: const ValueKey("empty"),
                              style: theme.textTheme.bodyMedium!
                                  .copyWith(color: theme.hintColor),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              text,
                              key: ValueKey(text),
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Stop / cancel button
                  TextButton.icon(
                    onPressed: controller.stopListening,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text("Stop"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated 5-bar sound-wave visualizer
class _SoundWave extends StatelessWidget {
  final double progress;
  final Color color;

  const _SoundWave({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    const barCount = 5;
    const maxHeight = 36.0;
    const minHeight = 6.0;

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          // each bar has a different phase offset
          final phase = (progress + i / barCount) % 1.0;
          final height =
              minHeight + (maxHeight - minHeight) * sin(phase * pi).abs();
          return AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 5,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5 + 0.5 * sin(phase * pi).abs()),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
