import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/controllers/profile_controller.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class LivePage extends StatefulWidget {
  final String liveID;
  final bool isHost;

  const LivePage({Key? key, required this.liveID, this.isHost = false}) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    profileController.updateUserId(widget.liveID); // Ensure the correct userID is updated
  }

  @override
  void dispose() {
    // Clean up the controller if needed
    Get.delete<ProfileController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (controller) {
        // Check for user data and loading state
        if (controller.user.isEmpty || controller.user['id'] == null || controller.user['name'] == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: ZegoUIKitPrebuiltLiveStreaming(
            appID: 1606675488, // Replace with your appID
            appSign: "05fa1d5b330b5e4d2e6de1dfa3ea3d3eb4c6fb9432ceb3930fc818d6de17b9e7", // Replace with your appSign
            userID: controller.user['id'] ?? '', // Ensure userID fallback is handled
            userName: controller.user['name'] ?? 'Unknown User', // Fallback to default if name is null
            liveID: widget.liveID,
            config: widget.isHost
                ? ZegoUIKitPrebuiltLiveStreamingConfig.host(
                    plugins: [ZegoUIKitSignalingPlugin()],
                  )
                : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
                    plugins: [ZegoUIKitSignalingPlugin()],
                  ),
          ),
        );
      },
    );
  }
}
