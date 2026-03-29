import 'package:harmonymusic/services/stream_service.dart'show Audio;

class HMStreamingData {
  final bool playable;
  final String statusMSG;
  final Audio? lowQualityAudio;
  final Audio? highQualityAudio;
  final Audio? ultraHighQualityAudio;
  int qualityIndex = 1;

  HMStreamingData({
    required this.playable,
    required this.statusMSG,
    this.lowQualityAudio,
    this.highQualityAudio,
    this.ultraHighQualityAudio,
  });

  setQualityIndex(int index) {
    qualityIndex = index;
  }

  Audio? get audio {
    if (qualityIndex == 0) return lowQualityAudio;
    if (qualityIndex == 2) return ultraHighQualityAudio ?? highQualityAudio;
    return highQualityAudio;
  }

  factory HMStreamingData.fromJson(json) {
    if (!json['playable']) {
      return HMStreamingData(
        playable: false,
        statusMSG: json['statusMSG'],
      );
    }
    final lowQualityAudio = Audio.fromJson(json['lowQualityAudio']);
    final highQualityAudio = Audio.fromJson(json['highQualityAudio']);
    final ultraHighQualityAudio = json['ultraHighQualityAudio'] != null
        ? Audio.fromJson(json['ultraHighQualityAudio'])
        : null;
    return HMStreamingData(
        playable: json['playable'],
        statusMSG: json['statusMSG'],
        lowQualityAudio: lowQualityAudio,
        highQualityAudio: highQualityAudio,
        ultraHighQualityAudio: ultraHighQualityAudio);
  }

  Map<String, dynamic> toJson() => {
        "playable": playable,
        "statusMSG": statusMSG,
        "lowQualityAudio": lowQualityAudio?.toJson(),
        "highQualityAudio": highQualityAudio?.toJson(),
        "ultraHighQualityAudio": ultraHighQualityAudio?.toJson(),
      };
}
