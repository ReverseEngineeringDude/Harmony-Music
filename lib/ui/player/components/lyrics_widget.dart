import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';


import '../../widgets/shimmer_widgets/lyrics_shimmer.dart';
import '../player_controller.dart';
import 'smooth_lyrics_reader.dart';
import '../../screens/Settings/settings_screen_controller.dart';

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
                        pc.progressBarStatus.value.current.inMilliseconds + pc.lyricsOffset.value,
                    model: LyricsModelBuilder.create()
                        .bindLyricToMain(pc.lyrics['synced'].toString())
                        .getModel(),
                    emptyBuilder: () => _SyncedEmptyWidget(pc: pc),
                  );
                  return IgnorePointer(ignoring: hasSynced, child: reader);
                })(),

          if (pc.lyricsMode.toInt() == 0 && (pc.lyrics['synced'] ?? '').toString().trim().isNotEmpty)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TransliterateButton(pc: pc),
                  _LyricsOffsetControls(pc: pc),
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

    final TextStyle labelStyle = isDesktop
        ? Theme.of(context).textTheme.titleMedium!
        : Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Colors.white);

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('syncedLyricsNotAvailable'.tr, style: labelStyle),
            ],
          ),
        ),
      );
  }
}class _LyricsOffsetControls extends StatelessWidget {
  final PlayerController pc;
  const _LyricsOffsetControls({required this.pc});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = pc.isDesktopLyricsDialogOpen;
    final bgColor = isDesktop
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : Colors.black.withValues(alpha: 0.55);
    final fgColor = isDesktop
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => pc.lyricsOffset.value -= 500,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.remove, size: 18, color: fgColor),
            ),
          ),
          Obx(() {
            final offsetSec = pc.lyricsOffset.value / 1000.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                '${offsetSec > 0 ? '+' : ''}${offsetSec.toStringAsFixed(1)}s',
                style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            );
          }),
          InkWell(
            onTap: () => pc.lyricsOffset.value += 500,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.add, size: 18, color: fgColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransliterateButton extends StatelessWidget {
  final PlayerController pc;
  const _TransliterateButton({required this.pc});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = pc.isDesktopLyricsDialogOpen;
    final bgColor = isDesktop
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : Colors.black.withValues(alpha: 0.55);
    final fgColor = isDesktop
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    return Obx(() {
      if (Get.find<SettingsScreenController>().isTransliterationEnabled.isFalse) {
        return const SizedBox.shrink();
      }
      final isTransliterating = pc.isLyricsTransliterating.value;
      final isTransliterated = pc.isLyricsTransliterated.value;

      return InkWell(
        onTap: isTransliterating ? null : pc.transliterateLyrics,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isTransliterated ? Colors.teal : bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTransliterating)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: isTransliterated ? Colors.white : fgColor),
                )
              else
                Icon(isTransliterated ? Icons.spellcheck : Icons.translate, size: 16, color: isTransliterated ? Colors.white : fgColor),
              const SizedBox(width: 4),
              Text(
                isTransliterated ? 'Transliterated' : 'Transliterate',
                style: TextStyle(
                  color: isTransliterated ? Colors.white : fgColor,
                  fontSize: 12,
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
