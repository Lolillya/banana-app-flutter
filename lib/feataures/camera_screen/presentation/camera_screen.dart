import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  void dispose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildUI());
  }

  Future<void> _setupCameraController() async {
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      setState(() {
        cameras = cameras;
        cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
      });
      cameraController?.initialize().then((_) {
        setState(() {});
      });
    }
  }

  Widget? _buildUI() {
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing Camera & ML Model...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SafeArea(child: CameraPreview(cameraController!)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: "capture",
                onPressed: () => Navigator.pushNamed(context, '/results'),
                backgroundColor: Colors.blue,
                child: const Icon(Icons.camera_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class YoloView extends StatelessWidget {
  const YoloView({super.key});

  @override
  Widget build(BuildContext context) {
    return YOLOView(
      modelPath: "best_float32.tflite",
      task: YOLOTask.detect,
      onResult: (results) {
        if (kDebugMode) {
          print('${results.length}');
        }
        for (final result in results) {
          if (kDebugMode) {
            print('${result.className}: ${result.confidence}');
          }
        }
      },
    );
  }
}

class TestYolo extends StatelessWidget {
  const TestYolo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Testt YOLO"),
          onPressed: () async {
            try {
              final yolo = YOLO(
                modelPath: 'best_float32',
                task: YOLOTask.detect,
              );

              await yolo.loadModel();
              if (kDebugMode) {
                print('YOLO loaded');
              }

              ScaffoldMessenger.of(
                // ignore: use_build_context_synchronously
                context,
              ).showSnackBar(SnackBar(content: Text("Yolo working")));
            } catch (e) {
              if (kDebugMode) {
                print('$e');
              }
              ScaffoldMessenger.of(
                // ignore: use_build_context_synchronously
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
        ),
      ),
    );
  }
}
