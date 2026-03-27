import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';

/// Premium lyrics highlighter UI.
///
/// Active line: large, bold, white — visually pops.
/// Inactive lines: small, partially transparent — fade into the background.
/// Highlight sweep color: picks from the dominant theme color.
class HarmonyLyricUI extends LyricUI {
  final Color highlightColor;
  final double activeFontSize;
  final double inactiveFontSize;
  final double lineGap;

  HarmonyLyricUI({
    this.highlightColor = Colors.white,
    this.activeFontSize = 22,
    this.inactiveFontSize = 15,
    this.lineGap = 28,
  });

  @override
  TextStyle getPlayingMainTextStyle() => TextStyle(
        color: Colors.white,
        fontSize: activeFontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        shadows: [
          Shadow(
            color: highlightColor.withValues(alpha: 0.6),
            blurRadius: 12,
          ),
        ],
      );

  @override
  TextStyle getOtherMainTextStyle() => TextStyle(
        color: Colors.white.withValues(alpha: 0.38),
        fontSize: inactiveFontSize,
        fontWeight: FontWeight.w400,
      );

  @override
  TextStyle getPlayingExtTextStyle() => TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: inactiveFontSize,
      );

  @override
  TextStyle getOtherExtTextStyle() => TextStyle(
        color: Colors.white.withValues(alpha: 0.28),
        fontSize: inactiveFontSize - 2,
      );

  @override
  double getLineSpace() => lineGap;

  @override
  double getInlineSpace() => 20;

  @override
  double getPlayingLineBias() => 0.3;

  @override
  LyricAlign getLyricHorizontalAlign() => LyricAlign.CENTER;

  @override
  LyricBaseLine getBiasBaseLine() => LyricBaseLine.CENTER;

  @override
  bool enableHighlight() => true;

  @override
  bool enableLineAnimation() => true;

  @override
  Color getLyricHightlightColor() => highlightColor;

  @override
  HighlightDirection getHighlightDirection() => HighlightDirection.LTR;
}
