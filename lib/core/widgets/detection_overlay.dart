import 'package:flutter/material.dart';
import '../services/ml_service.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  final Size imageSize;
  final Size screenSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoundingBoxPainter(
        detections: detections,
        imageSize: imageSize,
        screenSize: screenSize,
      ),
      size: screenSize,
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;
  final Size screenSize;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate scale factors
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    for (final detection in detections) {
      // Scale bounding box coordinates
      final left = detection.x * scaleX;
      final top = detection.y * scaleY;
      final width = detection.width * scaleX;
      final height = detection.height * scaleY;

      // Choose color based on class
      final color = _getColorForClass(detection.classId);
      paint.color = color;

      // Draw bounding box
      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, paint);

      // Prepare label text
      final label =
          '${detection.className} ${(detection.confidence * 100).toStringAsFixed(1)}%';

      // Create text span with background
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        ),
      );

      textPainter.layout();

      // Draw label background
      final labelRect = Rect.fromLTWH(
        left,
        top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      final backgroundPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRect(labelRect, backgroundPaint);

      // Draw label text
      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 2));
    }
  }

  Color _getColorForClass(int classId) {
    // Generate consistent colors for different classes
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.yellow,
      Colors.indigo,
      Colors.teal,
    ];

    return colors[classId % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DetectionStats extends StatelessWidget {
  final List<Detection> detections;
  final double inferenceTime;

  const DetectionStats({
    super.key,
    required this.detections,
    required this.inferenceTime,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detections: ${detections.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Inference: ${inferenceTime.toStringAsFixed(1)}ms',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (detections.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...detections
                  .take(3)
                  .map(
                    (detection) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${detection.className}: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              if (detections.length > 3)
                Text(
                  '... and ${detections.length - 3} more',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
