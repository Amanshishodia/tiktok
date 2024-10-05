import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok/constants.dart';
import 'package:tiktok/models/video.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tiktok/models/video_adapter.dart';

class VideoController extends GetxController {
  final Rx<List<Video>> _videoList = Rx<List<Video>>([]);
  final isLoading = false.obs;
  late Box<Video> _videoBox;

  List<Video> get videoList => _videoList.value;

  @override
  void onInit() async {
    super.onInit();
    await _initHive();
    isLoading.value = true;
    _loadCachedVideos();
    _bindFirestoreStream();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VideoAdapter());
    _videoBox = await Hive.openBox<Video>('videos');
  }

  void _loadCachedVideos() {
    final cachedVideos = _videoBox.values.toList();
    if (cachedVideos.isNotEmpty) {
      _videoList.value = cachedVideos;
      isLoading.value = false;
    }
  }

  void _bindFirestoreStream() {
    _videoList.bindStream(
      firestore.collection('videos').snapshots().map((QuerySnapshot query) {
        List<Video> retVal = [];
        for (var element in query.docs) {
          final video = Video.fromSnap(element);
          retVal.add(video);
          _videoBox.put(video.id, video);
        }
        isLoading.value = false;
        return retVal;
      })
    );
  }

  Future<void> likeVideo(String id) async {
    try {
      DocumentSnapshot doc = await firestore.collection('videos').doc(id).get();
      var uid = authController.user.uid;
      if ((doc.data()! as dynamic)['likes'].contains(uid)) {
        await firestore.collection('videos').doc(id).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await firestore.collection('videos').doc(id).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      // Update the cached video
      final cachedVideo = _videoBox.get(id);
      if (cachedVideo != null) {
        if (cachedVideo.likes.contains(uid)) {
          cachedVideo.likes.remove(uid);
        } else {
          cachedVideo.likes.add(uid);
        }
        await _videoBox.put(id, cachedVideo);
      }
    } catch (e) {
      print("Error liking video: $e");
    }
  }

  @override
  void onClose() {
    _videoBox.close();
    super.onClose();
  }
}