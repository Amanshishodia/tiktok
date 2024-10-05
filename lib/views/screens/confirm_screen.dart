import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok/controllers/upload_video_controller.dart';
import 'package:tiktok/views/widgets/text_input_field.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

class ConfirmScreen extends StatefulWidget {
  final File videoFile;
  final String videoPath;

  const ConfirmScreen({
    Key? key,
    required this.videoFile,
    required this.videoPath,
  }) : super(key: key);

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  late VideoPlayerController controller;
  TextEditingController _songController = TextEditingController();
  TextEditingController _captionController = TextEditingController();
  UploadVideoController uploadVideoController = Get.put(UploadVideoController());

  List<Filter> filters = [
    Filter('Normal', null),
    Filter('Sepia', 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131'),
    Filter('Grayscale', 'colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3'),
    Filter('Invert', 'negate'),
    Filter('Vintage', 'curves=vintage'),
    Filter('Vignette', 'vignette'),
  ];

  int selectedFilterIndex = 0;
  bool isProcessing = false;
  String? filteredVideoPath;

  // Dropdown for song selection
  String selectedSong = "No Sound"; // Default value
  List<String> songs = [
    "No Sound",
    "song1.mp3",
    "song2.mp3",
    "song3.mp3",
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo(widget.videoFile);
  }

  void _initializeVideo(File videoFile) {
    controller = VideoPlayerController.file(videoFile);
    controller.initialize().then((_) {
      setState(() {});
      controller.play();
      controller.setVolume(1);
      controller.setLooping(true);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> applyFilter(int index) async {
    if (index == selectedFilterIndex) return;

    setState(() {
      isProcessing = true;
      selectedFilterIndex = index;
    });

    if (filters[index].ffmpegFilter == null) {
      await controller.dispose();
      _initializeVideo(widget.videoFile);
      setState(() {
        isProcessing = false;
        filteredVideoPath = null;
      });
      return;
    }

    final String outputPath = await getTemporaryDirectory().then((dir) => '${dir.path}/filtered_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

    final String ffmpegCommand = '-i ${widget.videoPath} -vf ${filters[index].ffmpegFilter} -c:a copy $outputPath';

    await FFmpegKit.execute(ffmpegCommand).then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await controller.dispose();
        final filteredFile = File(outputPath);
        _initializeVideo(filteredFile);
        setState(() {
          isProcessing = false;
          filteredVideoPath = outputPath;
        });
      } else {
        print('FFmpeg process failed with return code $returnCode');
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

 Future<void> replaceVideoAudio(String videoPath) async {
  // Use filteredVideoPath if a filter was applied, otherwise use the original videoPath
  final String videoToProcess = filteredVideoPath ?? videoPath;

  final String outputPath = await getTemporaryDirectory().then(
    (dir) => '${dir.path}/final_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
  );

  String ffmpegCommand;

  if (selectedSong == "No Sound") {
    // If "No Sound" is selected, remove audio from the video (filtered or unfiltered)
    ffmpegCommand = '-i $videoToProcess -c:v copy -an $outputPath';
  } else {
    // If a song is selected, add the song to the video (filtered or unfiltered)
    final audioPath = (await _getAudioFile(selectedSong)).path; // Get the audio file
    ffmpegCommand = '-i $videoToProcess -i $audioPath -map 0:v -map 1:a -c:v copy -shortest $outputPath';
  }

  await FFmpegKit.execute(ffmpegCommand).then((session) async {
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      print("Audio successfully replaced with $selectedSong!");

      // Update the video player with the new video (filtered + audio or unfiltered + audio)
      _initializeVideo(File(outputPath));
      setState(() {
        filteredVideoPath = outputPath; // Update filtered video path
      });
    } else {
      print("Audio replacement failed 😓");
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 1.5,
                  child: controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                if (isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => applyFilter(index),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedFilterIndex == index
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter),
                          Text(filters[index].name),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown for song selection
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: MediaQuery.of(context).size.width - 20,
              child: DropdownButton<String>(
                value: selectedSong,
                items: songs.map((String song) {
                  return DropdownMenuItem<String>(
                    value: song,
                    child: Text(song == "No Sound" ? "No Sound" : song),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSong = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: MediaQuery.of(context).size.width - 20,
              child: TextInputField(
                controller: _songController,
                labelText: 'Song Name',
                icon: Icons.music_note,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: MediaQuery.of(context).size.width - 20,
              child: TextInputField(
                controller: _captionController,
                labelText: 'Caption',
                icon: Icons.closed_caption,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () {
                      replaceVideoAudio(widget.videoPath).then((_) {
                        uploadVideoController.uploadVideo(
                          _songController.text,
                          _captionController.text,
                          filteredVideoPath ?? widget.videoPath,
                        );
                      });
                    },
              child: const Text(
                'Share!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Filter {
  final String name;
  final String? ffmpegFilter;

  Filter(this.name, this.ffmpegFilter);
}

Future<File> _getAudioFile(String song) async {
  final ByteData data = await rootBundle.load('asset/songs/$song');
  final List<int> bytes = data.buffer.asUint8List();
  final String dir = (await getTemporaryDirectory()).path;
  final File file = File('$dir/$song');
  await file.writeAsBytes(bytes);
  return file;
}