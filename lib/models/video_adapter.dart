import 'package:hive/hive.dart';
import 'package:tiktok/models/video.dart';

class VideoAdapter extends TypeAdapter<Video> {
  @override
  final int typeId = 0;

  @override
  Video read(BinaryReader reader) {
    return Video(
      username: reader.readString(),
      uid: reader.readString(),
      id: reader.readString(),
      likes: reader.readList().cast<String>(),
      commentCount: reader.readInt(),
      shareCount: reader.readInt(),
      songName: reader.readString(),
      caption: reader.readString(),
      videoUrl: reader.readString(),
      profilePhoto: reader.readString(),
      thumbnail: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Video obj) {
    writer.writeString(obj.username);
    writer.writeString(obj.uid);
    writer.writeString(obj.id);
    writer.writeList(obj.likes);
    writer.writeInt(obj.commentCount);
    writer.writeInt(obj.shareCount);
    writer.writeString(obj.songName);
    writer.writeString(obj.caption);
    writer.writeString(obj.videoUrl);
    writer.writeString(obj.profilePhoto);
    writer.writeString(obj.thumbnail);
  }
}