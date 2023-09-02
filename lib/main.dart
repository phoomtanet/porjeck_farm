import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;

  int? countCamera;
  int _countTime = 0;
  CameraController? _controller;
  bool statusVideo = false;
  @override
  void initState() {
    loadCamera();
    super.initState();
  }

  Future<void> loadCamera() async {
    final cameras = await availableCameras();
    setState(() {
      countCamera = cameras.length;
      if (countCamera! > 0) {
        _controller = CameraController(cameras[0], ResolutionPreset.max);
        _controller!.initialize().then((_) {
          if (!mounted) return;
          setState(() {});
        });
      } else {
        print("NO any camera found");
      }
    });
  }

  void _takePicture() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isInitialized) {
          XFile image = await _controller!.takePicture();
          await GallerySaver.saveImage(image.path, toDcim: true);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> startVideoRecording() async {
    try {
      await _controller!.startVideoRecording();
      setState(() {
        statusVideo = true;
        startTimer();
      });
    } on CameraException catch (e) {
      print('Error starting to record video: $e');
    }
  }

  Future<void> stopVideoRecording() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isRecordingVideo) {
          XFile videoFile = await _controller!.stopVideoRecording();

          // เก็บไฟล์วิดีโอในแกลลอรี่
          await GallerySaver.saveVideo(videoFile.path);

          setState(() {
            statusVideo = false;
            stopTimer();
          });
        }
      }
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) {
      setState(() {
        _countTime++;
      });
    });
  }

  // หยุดนับเวลาเมื่อหยุดอัดวิดีโอ
  void stopTimer() {
    _timer.cancel();
    setState(() {
      _countTime = 0;
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String formattedTime =
        '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _controller == null
              ? const Text('NO any camera found')
              : _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : const CircularProgressIndicator(),
          // เพิ่มข้อความกลางจอบน
          if (statusVideo)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 40),
                child: Text(
                  'กำลังบันทึกวิดีโอ ${formatTime(_countTime)}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!statusVideo)
                    Container(
                      margin: const EdgeInsets.only(
                          left: 10,
                          right: 80.0), // ใส่ margin ขาดข้างขวาของปุ่มถ่ายรูป
                      child: FloatingActionButton(
                        onPressed: () {
                          _takePicture();
                          Vibration.vibrate();
                        },
                        tooltip: 'Take Picture',
                        backgroundColor: const Color.fromARGB(255, 233, 22, 10),
                        child: const Icon(Icons.camera),
                      ),
                    ),
                  // ปุ่มเริ่มบันทึกวิดิโอ
                  if (!statusVideo)
                    FloatingActionButton(
                      onPressed: () {
                        startVideoRecording();
                        Vibration.vibrate();
                      },
                      tooltip: 'Start Recording',
                      backgroundColor: const Color.fromARGB(255, 16, 165, 211),
                      child: const Icon(Icons.videocam),
                    ),
                  // ปุ่มหยุดบันทึกวิดิโอ
                  if (statusVideo)
                    FloatingActionButton(
                      onPressed: () {
                        stopVideoRecording();
                      },
                      tooltip: 'Stop Recording',
                      backgroundColor: const Color.fromARGB(255, 233, 22, 10),
                      child: const Icon(Icons.stop),
                    ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer.cancel(); // ยกเลิก Timer เมื่อหน้าจอถูก dispose
    super.dispose();
  }
}
