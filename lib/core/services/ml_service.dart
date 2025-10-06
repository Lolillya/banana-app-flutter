import 'dart:typed_data';
import 'package:ultralytics_yolo/yolo.dart';

class Detection {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final int classId;
  final String className;

  Detection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.classId,
    required this.className,
  });
}

class MLService {
  static const String modelPath = 'best_float32.tflite';
  static const double confidenceThreshold = 0.5;

  YOLO? _model;
  bool _isModelLoaded = false;

  // Banana leaf disease labels (matching your YAML order)
  static const List<String> _labels = [
    'Banana Xanthomas Wilt', // 0
    'Bunchy Top Virus', // 1
    'Fusarium Wilt', // 2
    'Moko Disease', // 3
    'Yellow Sigatoka', // 4
  ];

  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    try {
      print('Loading YOLO model from: $modelPath');

      // Initialize YOLO model
      _model = YOLO(modelPath: modelPath, useGpu: false, task: YOLOTask.detect);

      await _model!.loadModel();

      _isModelLoaded = true;
      print('YOLO model loaded successfully');
    } catch (e) {
      print('Error loading YOLO model: $e');
      print('Model path: $modelPath');
      _isModelLoaded = false;
      rethrow; // Re-throw to help with debugging
    }
  }

  Future<List<Detection>> detectObjects(Uint8List imageBytes) async {
    if (!_isModelLoaded || _model == null) {
      print('Model not loaded or null');
      return [];
    }

    try {
      print('Running YOLO inference on ${imageBytes.length} bytes...');

      // Run YOLO inference
      final results = await _model!.predict(imageBytes);
      print('Raw YOLO results: $results');

      final boxes = results['boxes'] ?? [];
      print('Found ${boxes.length} raw detections');

      // Convert YOLO results to our Detection format
      final detections = boxes
          .map<Detection>((box) {
            final classId = box['class'] ?? 0;
            final className = (classId < _labels.length)
                ? _labels[classId]
                : 'Unknown';

            return Detection(
              x: box['x']?.toDouble() ?? 0.0,
              y: box['y']?.toDouble() ?? 0.0,
              width: box['width']?.toDouble() ?? 0.0,
              height: box['height']?.toDouble() ?? 0.0,
              confidence: box['confidence']?.toDouble() ?? 0.0,
              classId: classId,
              className: className,
            );
          })
          .where((detection) => detection.confidence >= confidenceThreshold)
          .toList();

      print(
        'Found ${detections.length} detections above ${confidenceThreshold * 100}% confidence',
      );
      return detections;
    } catch (e) {
      print('Error during YOLO inference: $e');
      print('Error type: ${e.runtimeType}');
      return [];
    }
  }

  void dispose() {
    _model = null;
    _isModelLoaded = false;
  }
}
