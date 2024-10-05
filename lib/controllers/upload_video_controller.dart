import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:tiktok/constants.dart';
import 'package:tiktok/models/video.dart';
import 'package:path/path.dart' as path;

class UploadVideoController extends GetxController {
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  Future<String> _uploadVideoToStorage(String id, String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception('Video file does not exist at path: $videoPath');
      }

      print('Starting video upload for file: $videoPath');
      print('File size: ${await file.length()} bytes');

      final fileName = path.basename(videoPath);
      final ref = firebaseStorage.ref().child('videos').child(id).child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        uploadProgress.value = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(uploadProgress.value * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('Video uploaded successfully. Download URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
    } catch (error) {
      print('Error uploading video: $error');
      Get.snackbar('Upload Error', 'Failed to upload video: $error',
          duration: Duration(seconds: 5), snackPosition: SnackPosition.BOTTOM);
      return '';
    }
  }

  Future<String> _uploadImageToStorage(String id, String videoPath) async {
    try {
      // For now, we'll use a placeholder image instead of generating a thumbnail
      final placeholderImageUrl = 'https://via.placeholder.com/150';
      print('Using placeholder image: $placeholderImageUrl');
      return placeholderImageUrl;
    } catch (e) {
      print('Error with thumbnail: $e');
      Get.snackbar('Error', 'Failed to handle thumbnail: $e',
          duration: Duration(seconds: 5), snackPosition: SnackPosition.BOTTOM);
      return '';
    }
  }

  Future<void> uploadVideo(String songName, String caption, String videoPath) async {
    try {
      isUploading.value = true;

      final uid = firebaseAuth.currentUser!.uid;
      final userDoc = await firestore.collection('users').doc(uid).get();
      final allDocs = await firestore.collection('videos').get();
      final len = allDocs.docs.length;

      final actualVideoPath = videoPath.startsWith('/') ? videoPath : File(videoPath).path;

      print('Starting video upload process for file: $actualVideoPath');
      final videoUrl = await _uploadVideoToStorage("Video_$len", actualVideoPath);
      if (videoUrl.isEmpty) {
        throw Exception('Failed to upload video: returned URL is empty');
      }

      final thumbnail = await _uploadImageToStorage("Video_$len", actualVideoPath);
      if (thumbnail.isEmpty) {
        throw Exception('Failed to handle thumbnail: returned URL is empty');
      }

      final video = Video(
        username: (userDoc.data()! as Map<String, dynamic>)['name'],
        uid: uid,
        id: "Video_$len",
        likes: [],
        commentCount: 0,
        shareCount: 0,
        songName: songName,
        caption: caption,
        videoUrl: videoUrl,
        profilePhoto: (userDoc.data()! as Map<String, dynamic>)['profilePhoto'],
        thumbnail: thumbnail,
      );

      await firestore.collection('videos').doc('Video_$len').set(video.toJson());
      Get.back();
      Get.snackbar('Success', 'Video uploaded successfully');
    } catch (e) {
      print('Error during video upload process: $e');
      Get.snackbar(
        'Upload Error', 
        'An error occurred during the upload process: ${e.toString()}',
        duration: Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }
}
