import 'package:get/get.dart';
import '../models/hm_streaming_data.dart';
import '../services/stream_service.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';

class StreamingQualityService extends GetxService {
  final SettingsScreenController _settingsController = Get.find<SettingsScreenController>();

  /// Returns the appropriate [Audio] stream based on user settings and availability.
  /// 
  /// Priority for Ultra HQ:
  /// 1. ultraHighQualityAudio
  /// 2. highQualityAudio
  /// 3. lowQualityAudio
  Audio? getBestAudio(HMStreamingData streamData) {
    if (!streamData.playable) return null;

    final bool isUltraEnabled = _settingsController.setBox.get('ultraHighQualityEnabled') ?? false;
    final int qualityIndex = _settingsController.streamingQuality.value.index;

    if (isUltraEnabled) {
      return streamData.ultraHighQualityAudio ?? 
             streamData.highQualityAudio ?? 
             streamData.lowQualityAudio;
    }

    // Normal behavior based on quality index (0: Low, 1: High, 2: Ultra)
    // Note: AudioQuality.Ultra is index 2.
    if (qualityIndex == 2) { // Ultra selected in dropdown (optional path)
       return streamData.ultraHighQualityAudio ?? 
             streamData.highQualityAudio ?? 
             streamData.lowQualityAudio;
    } else if (qualityIndex == 1) { // High
      return streamData.highQualityAudio ?? streamData.lowQualityAudio;
    } else { // Low
      return streamData.lowQualityAudio ?? streamData.highQualityAudio;
    }
  }

  /// Sets the quality index on [streamData] for the current playback session.
  void applyQualitySelection(HMStreamingData streamData) {
    final bool isUltraEnabled = _settingsController.setBox.get('ultraHighQualityEnabled') ?? false;
    
    if (isUltraEnabled) {
      streamData.setQualityIndex(2); // Ultra index
    } else {
      streamData.setQualityIndex(_settingsController.streamingQuality.value.index);
    }
  }
}
