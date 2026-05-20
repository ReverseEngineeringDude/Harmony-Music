import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../widgets/shimmer_widgets/lyrics_shimmer.dart';
import '../player_controller.dart';
import 'smooth_lyrics_reader.dart';

class LyricsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const LyricsWidget({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    return Obx(() {
      // ── Loading ─────────────────────────────────────────────────────────────
      if (pc.isLyricsLoading.isTrue) {
        return const Center(child: LyricsShimmerWidget());
      }

      // ── No lyrics found → show "Use AI" prompt ───────────────────────────
      if (pc.isNoLyricsFound.isTrue) {
        return _NoLyricsWidget(pc: pc);
      }

      // ── Lyrics loaded ────────────────────────────────────────────────────
      final hasLyrics = (pc.lyrics['plainLyrics'] ?? '').isNotEmpty &&
          pc.lyrics['plainLyrics'] != 'NA';

      return Stack(
        children: [
          // Main lyrics content
          pc.lyricsMode.toInt() == 1
              ? Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: padding,
                    child: TextSelectionTheme(
                      data: Theme.of(context).textSelectionTheme,
                      child: SelectableText(
                        pc.lyrics['plainLyrics'] == 'NA'
                            ? 'lyricsNotAvailable'.tr
                            : pc.lyrics['plainLyrics'],
                        textAlign: TextAlign.center,
                        style: pc.isDesktopLyricsDialogOpen
                            ? Theme.of(context).textTheme.titleMedium!
                            : Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : (() {
                  // Only block touch when synced lyrics are actually rendering;
                  // when emptyBuilder shows, we need taps for the button.
                  final hasSynced =
                      (pc.lyrics['synced'] ?? '').toString().trim().isNotEmpty;
                  final reader = SmoothLyricsReader(
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    lyricUi: pc.lyricUi,
                    position:
                        pc.progressBarStatus.value.current.inMilliseconds,
                    model: LyricsModelBuilder.create()
                        .bindLyricToMain(pc.lyrics['synced'].toString())
                        .getModel(),
                    emptyBuilder: () => _SyncedEmptyWidget(pc: pc),
                  );
                  return IgnorePointer(ignoring: hasSynced, child: reader);
                })(),

          // ── Bottom action bar ────────────────────────────────────────────
          if (hasLyrics)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Translate button (left)
                  _TranslateButton(pc: pc),
                  // AI badge + retry (right)
                  if (pc.isLyricsAiGenerated.isTrue)
                    _AiBadge(pc: pc),
                ],
              ),
            ),
        ],
      );
    });
  }
}

// ── Synced lyrics not available state ───────────────────────────────────────

class _SyncedEmptyWidget extends StatelessWidget {
  final PlayerController pc;
  const _SyncedEmptyWidget({required this.pc});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = pc.isDesktopLyricsDialogOpen;
    final Color textColor = isDesktop ? Colors.black54 : Colors.white70;
    final TextStyle labelStyle = isDesktop
        ? Theme.of(context).textTheme.titleMedium!
        : Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Colors.white);

    final bool hasApiKey =
        ((Hive.box('AppPrefs').get('geminiApiKey') as String?) ?? '').isNotEmpty;
    final bool hasPlain = (pc.lyrics['plainLyrics'] ?? '').isNotEmpty &&
        pc.lyrics['plainLyrics'] != 'NA';

    return Obx(() {
      if (pc.isSyncedLyricsGenerating.isTrue) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: isDesktop ? null : Colors.white),
              const SizedBox(height: 12),
              Text('generatingLyrics'.tr, style: labelStyle),
            ],
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('syncedLyricsNotAvailable'.tr, style: labelStyle),
              if (hasPlain && hasApiKey) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('generateAiSyncedLyrics'.tr),
                  onPressed: pc.generateAiSyncedLyrics,
                ),
              ] else if (!hasApiKey && hasPlain) ...[
                const SizedBox(height: 8),
                Text(
                  'setGeminiKeyForAiLyrics'.tr,
                  style: TextStyle(color: textColor, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

// ── "No lyrics found" state ──────────────────────────────────────────────────

class _NoLyricsWidget extends StatelessWidget {
  final PlayerController pc;
  const _NoLyricsWidget({required this.pc});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = pc.isDesktopLyricsDialogOpen;
    final Color textColor = isDesktop ? Colors.black54 : Colors.white70;
    final bool hasApiKey =
        ((Hive.box('AppPrefs').get('geminiApiKey') as String?) ?? '').isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_outlined,
                size: 52, color: isDesktop ? Colors.black26 : Colors.white30),
            const SizedBox(height: 12),
            Text(
              'lyricsNotAvailable'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            if (hasApiKey)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text('useAiToFindLyrics'.tr),
                onPressed: pc.generateAiLyrics,
              )
            else
              TextButton.icon(
                icon: Icon(Icons.settings_outlined,
                    size: 16, color: textColor),
                label: Text(
                  'setGeminiKeyForAiLyrics'.tr,
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
                onPressed: () => pc.showLyrics(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Translate button (bottom-left) ───────────────────────────────────────────

class _TranslateButton extends StatelessWidget {
  final PlayerController pc;
  const _TranslateButton({required this.pc});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = pc.isDesktopLyricsDialogOpen;
    final bool hasApiKey =
        ((Hive.box('AppPrefs').get('geminiApiKey') as String?) ?? '').isNotEmpty;

    if (!hasApiKey) return const SizedBox.shrink();

    return Obx(() {
      final translating = pc.isLyricsTranslating.isTrue;
      final translated = pc.isLyricsTranslated.isTrue;

      final bgColor = isDesktop
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.black.withValues(alpha: 0.55);
      final fgColor = isDesktop
          ? Theme.of(context).colorScheme.onSurface
          : Colors.white;

      return GestureDetector(
        onTap: translating ? null : pc.translateLyricsWithAi,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: translated
                ? Colors.teal.withValues(alpha: isDesktop ? 1 : 0.85)
                : bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (translating)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: fgColor,
                  ),
                )
              else
                Icon(
                  translated ? Icons.check_circle_outline : Icons.translate,
                  size: 13,
                  color: translated ? Colors.white : fgColor,
                ),
              const SizedBox(width: 5),
              Text(
                translated
                    ? 'lyricsTranslated'.tr
                    : translating
                        ? 'translatingLyrics'.tr
                        : 'translateLyrics'.tr,
                style: TextStyle(
                  color: translated ? Colors.white : fgColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── AI badge + retry (bottom-right) ─────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  final PlayerController pc;
  const _AiBadge({required this.pc});

  @override
  Widget build(BuildContext context) {
  final bool isDesktop = pc.isDesktopLyricsDialogOpen;
    final bgColor = isDesktop
        ? Theme.of(context).colorScheme.primaryContainer
        : Colors.deepPurple.withValues(alpha: 0.85);
    final fgColor = isDesktop
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "✦ AI" pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20), right: Radius.circular(4)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: fgColor),
              const SizedBox(width: 4),
              Text('AI',
                  style: TextStyle(
                      color: fgColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        const SizedBox(width: 2),
        // Retry button
        Tooltip(
          message: 'retryAiLyrics'.tr,
          child: InkWell(
            onTap: pc.retryAiLyrics,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4), right: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4), right: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Icon(Icons.refresh_rounded, size: 13, color: fgColor),
            ),
          ),
        ),
      ],
    );
  }
}
