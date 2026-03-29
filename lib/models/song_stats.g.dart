// Hand-written Hive type adapter for SongStats.
// TypeId 10 — keep this unique across the app.
// ignore_for_file: type=lint

import 'package:hive/hive.dart';
import 'song_stats.dart';

class SongStatsAdapter extends TypeAdapter<SongStats> {
  @override
  final int typeId = 10;

  @override
  SongStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongStats(
      songId: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      artUri: fields[3] as String,
      artistIds: (fields[4] as List).cast<String>(),
      playCount: fields[5] as int,
      skipCount: fields[6] as int,
      isLiked: fields[7] as bool,
      listenedSeconds: fields[8] as int,
      lastPlayedAt: fields[9] as DateTime,
      score: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SongStats obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.artUri)
      ..writeByte(4)
      ..write(obj.artistIds)
      ..writeByte(5)
      ..write(obj.playCount)
      ..writeByte(6)
      ..write(obj.skipCount)
      ..writeByte(7)
      ..write(obj.isLiked)
      ..writeByte(8)
      ..write(obj.listenedSeconds)
      ..writeByte(9)
      ..write(obj.lastPlayedAt)
      ..writeByte(10)
      ..write(obj.score);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
