import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';



@HiveType(typeId: 0)
class Video {
  @HiveField(0)
  String username;
  @HiveField(1)
  String uid;
  @HiveField(2)
  String id;
  @HiveField(3)
  List<String> likes;
  @HiveField(4)
  int commentCount;
  @HiveField(5)
  int shareCount;
  @HiveField(6)
  String songName;
  @HiveField(7)
  String caption;
  @HiveField(8)
  String videoUrl;
  @HiveField(9)
  String profilePhoto;
  @HiveField(10)
  String thumbnail;

  Video({
    required this.username,
    required this.uid,
    required this.id,
    required this.likes,
    required this.commentCount,
    required this.shareCount,
    required this.songName,
    required this.caption,
    required this.videoUrl,
    required this.profilePhoto,
    required this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        "username": username,
        "uid": uid,
        "id": id,
        "likes": likes,
        "commentCount": commentCount,
        "shareCount": shareCount,
        "songName": songName,
        "caption": caption,
        "videoUrl": videoUrl,
        "profilePhoto": profilePhoto,
        "thumbnail": thumbnail,
      };

  static Video fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return Video(
      username: snapshot['username'],
      uid: snapshot['uid'],
      id: snapshot['id'],
      likes: List<String>.from(snapshot['likes']),
      commentCount: snapshot['commentCount'],
      shareCount: snapshot['shareCount'],
      songName: snapshot['songName'],
      caption: snapshot['caption'],
      videoUrl: snapshot['videoUrl'],
      profilePhoto: snapshot['profilePhoto'],
      thumbnail: snapshot['thumbnail'],
    );
  }
}