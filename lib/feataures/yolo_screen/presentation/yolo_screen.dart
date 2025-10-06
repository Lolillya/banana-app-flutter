import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:banana_app/feataures/results-screen/presentation/results_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_task.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:flutter/rendering.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  _CameraDetectionScreenState createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  late YOLOViewController controller;
  final GlobalKey _previewKey = GlobalKey(); // <-- for snapshot
  List<YOLOResult> currentResults = [];
  bool _hasPermission = false;
  bool _checkingPermission = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    controller = YOLOViewController();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _checkingPermission = false;
    });
  }

  Future<String> _capturePreviewToFile() async {
    // 1) Get the current UI image from the RepaintBoundary
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw 'Preview boundary not found';
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw 'Failed to encode image';

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    // 2) Save to a temporary file
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/yolo_capture_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(pngBytes, flush: true);

    return file.path;
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // Optionally pause the stream for a stable frame (uncomment if your controller supports it)
      // await controller.pause();

      final imagePath = await _capturePreviewToFile();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ResultsScreen(),
          settings: RouteSettings(
            arguments: {'imagePath': imagePath, 'results': currentResults},
          ),
        ),
      );

      // await controller.resume();
    } catch (e, st) {
      if (kDebugMode) {
        print('Save error: $e\n$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Camera permission is required.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final status = await Permission.camera.request();
                  setState(() => _hasPermission = status.isGranted);
                },
                child: const Text('Grant Permission'),
              ),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open App Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Wrap YOLOView with RepaintBoundary to snapshot the exact frame you see
          RepaintBoundary(
            key: _previewKey,
            child: YOLOView(
              modelPath:
                  'best_float32.tflite', // make sure it matches your assets path
              task: YOLOTask.detect,
              controller: controller,
              onResult: (results) {
                setState(() => currentResults = results);
              },
              onPerformanceMetrics: (metrics) {
                if (kDebugMode) {
                  print('FPS: ${metrics.fps.toStringAsFixed(1)}');
                  print(
                    'Processing time: ${metrics.processingTimeMs.toStringAsFixed(1)}ms',
                  );
                }
              },
            ),
          ),

          // Count overlay
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Objects: ${currentResults.length}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          // Save button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
