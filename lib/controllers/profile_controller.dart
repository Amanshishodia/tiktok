import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok/constants.dart';

class ProfileController extends GetxController {
  final Rx<Map<String, dynamic>> _user = Rx<Map<String, dynamic>>({});
  Map<String, dynamic> get user => _user.value;

  Rx<String> _uid = "".obs;

  updateUserId(String uid) {
    _uid.value = uid;
    getUserData();
  }

  getUserData() async {
    try {
      List<String> thumbnails = [];
      var myVideos = await firestore
          .collection('videos')
          .where('uid', isEqualTo: _uid.value)
          .get();

      for (int i = 0; i < myVideos.docs.length; i++) {
        thumbnails.add((myVideos.docs[i].data() as dynamic)['thumbnail']);
      }

      DocumentSnapshot userDoc = await firestore.collection('users').doc(_uid.value).get();

      if (userDoc.exists) {
        final userData = userDoc.data()! as dynamic;
        String name = userData['name'] ?? 'Unknown';  // Fallback if name is null
        String profilePhoto = userData['profilePhoto'] ?? '';
        String id = userDoc.id;  // Use Firestore doc ID as the user's ID

        int likes = 0;
        int followers = 0;
        int following = 0;
        bool isFollowing = false;

        for (var item in myVideos.docs) {
          likes += (item.data()['likes'] as List).length;
        }

        var followerDoc = await firestore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .get();
        var followingDoc = await firestore
            .collection('users')
            .doc(_uid.value)
            .collection('following')
            .get();

        followers = followerDoc.docs.length;
        following = followingDoc.docs.length;

        firestore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .doc(authController.user.uid)
            .get()
            .then((value) {
          isFollowing = value.exists;
        });

        _user.value = {
          'id': id,  // Ensure 'id' exists
          'followers': followers.toString(),
          'following': following.toString(),
          'isFollowing': isFollowing,
          'likes': likes.toString(),
          'profilePhoto': profilePhoto,
          'name': name,
          'thumbnails': thumbnails,
        };
        update();
      } else {
        // Handle the case where the user document does not exist
        print("User not found.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  followUser() async {
    var doc = await firestore
        .collection('users')
        .doc(_uid.value)
        .collection('followers')
        .doc(authController.user.uid)
        .get();

    if (!doc.exists) {
      await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('followers')
          .doc(authController.user.uid)
          .set({});
      await firestore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(_uid.value)
          .set({});
      _user.value.update(
        'followers',
        (value) => (int.parse(value) + 1).toString(),
      );
    } else {
      await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('followers')
          .doc(authController.user.uid)
          .delete();
      await firestore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(_uid.value)
          .delete();
      _user.value.update(
        'followers',
        (value) => (int.parse(value) - 1).toString(),
      );
    }
    _user.value.update('isFollowing', (value) => !value);
    update();
  }
}
