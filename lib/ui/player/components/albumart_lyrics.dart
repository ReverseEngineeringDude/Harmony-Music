import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/songinfo_bottom_sheet.dart';

class AlbumArtNLyrics extends StatefulWidget {
  const AlbumArtNLyrics({super.key, required this.playerArtImageSize});
  final double playerArtImageSize;

  @override
  State<AlbumArtNLyrics> createState() => _AlbumArtNLyricsState();
}

class _AlbumArtNLyricsState extends State<AlbumArtNLyrics>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;
  late Animation<double> _flightProgressAnimation;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.1), weight: 30),
    ]).animate(CurvedAnimation(
        parent: _heartAnimationController, curve: Curves.easeInOut));

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
        parent: _heartAnimationController, curve: Curves.easeInOut));

    _flightProgressAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
        parent: _heartAnimationController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    return Obx(() => playerController.currentSong.value != null
        ? Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    constraints: const BoxConstraints(maxWidth: 500),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10.0)),
                    ),
                    isScrollControlled: true,
                    context:
                        playerController.homeScaffoldkey.currentState!.context,
                    barrierColor: Colors.transparent.withAlpha(100),
                    builder: (context) => SongInfoBottomSheet(
                      playerController.currentSong.value!,
                      calledFromPlayer: true,
                    ),
                  ).whenComplete(() => Get.delete<SongInfoController>());
                },
                onTap: () {
                  playerController.showLyrics();
                },
                onDoubleTap: () {
                  if (playerController.showLyricsflag.isFalse) {
                    if (playerController.isCurrentSongFav.isFalse) {
                      playerController.toggleFavourite();
                    }
                    _heartAnimationController.forward(from: 0.0);
                  }
                },
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (playerController.showLyricsflag.isTrue) return;
                  if (details.primaryVelocity! < 0) {
                    playerController.next();
                  } else if (details.primaryVelocity! > 0) {
                    playerController.prev();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ImageWidget(
                      size: widget.playerArtImageSize,
                      song: playerController.currentSong.value!,
                      isPlayerArtImage: true,
                    ),

                    // Animated Heart Overlay
                    AnimatedBuilder(
                      animation: _heartAnimationController,
                      builder: (context, child) {
                        final isLandscape = context.isLandscape;
                        // Approximate distances to the real like button
                        final dx = isLandscape
                            ? widget.playerArtImageSize * 0.8
                            : widget.playerArtImageSize * 0.45;
                        final dy =
                            isLandscape ? 0.0 : widget.playerArtImageSize * 0.6;

                        return Transform.translate(
                          offset: Offset(dx * _flightProgressAnimation.value,
                              dy * _flightProgressAnimation.value),
                          child: Opacity(
                            opacity: _heartOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _heartScaleAnimation.value,
                              child: Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: widget.playerArtImageSize * 0.4,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Obx(() => playerController.showLyricsflag.isTrue
                  ? InkWell(
                      onTap: () {
                        playerController.showLyrics();
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                          child: Container(
                            height: widget.playerArtImageSize,
                            width: widget.playerArtImageSize,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6), // Dark overlay for contrast
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Stack(
                              children: [
                            LyricsWidget(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: widget.playerArtImageSize / 3.5)),
                            IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.90),
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.transparent,
                                      Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.90)
                                    ],
                                    stops: const [0, 0.2, 0.5, 0.8, 1],
                                  ),
                                ),
                              ),
                            )
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              if (playerController.isSleepTimerActive.isTrue)
                SizedBox(
                  width: widget.playerArtImageSize,
                  height: widget.playerArtImageSize,
                  //color: Colors.green,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 50,
                        width: 60,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(width: 1.3, color: Colors.white),
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withAlpha(150)),
                        child: IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              constraints: const BoxConstraints(maxWidth: 500),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10.0)),
                              ),
                              isScrollControlled: true,
                              context: playerController
                                  .homeScaffoldkey.currentState!.context,
                              barrierColor: Colors.transparent.withAlpha(100),
                              builder: (context) =>
                                  const SleepTimerBottomSheet(),
                            );
                          },
                          icon: const Icon(
                            Icons.timer,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          )
        : Container());
  }
}
