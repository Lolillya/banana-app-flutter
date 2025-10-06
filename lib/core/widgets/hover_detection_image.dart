import 'package:flutter/material.dart';
import 'dart:io';
import '../services/ml_service.dart';

class HoverDetectionImage extends StatefulWidget {
  final File imageFile;
  final List<Detection> detections;
  final double? width;
  final double? height;
  final BoxFit fit;

  const HoverDetectionImage({
    super.key,
    required this.imageFile,
    required this.detections,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<HoverDetectionImage> createState() => _HoverDetectionImageState();
}

class _HoverDetectionImageState extends State<HoverDetectionImage> {
  Offset? _hoverPosition;
  Detection? _hoveredDetection;
  Size? _imageSize;
  Size? _widgetSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: _onHover,
          onExit: _onExit,
          child: Stack(
            children: [
              // Image
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: Image.file(
                  widget.imageFile,
                  fit: widget.fit,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _calculateImageSize();
                          });
                        }
                        return child;
                      },
                ),
              ),
              // Hover overlay
              if (_hoveredDetection != null && _hoverPosition != null)
                Positioned(
                  left: _hoverPosition!.dx,
                  top: _hoverPosition!.dy,
                  child: _buildHoverBox(),
                ),
              // Detection bounding boxes (optional - for debugging)
              if (widget.detections.isNotEmpty)
                CustomPaint(
                  painter: DetectionBoxPainter(
                    detections: widget.detections,
                    imageSize: _imageSize ?? Size.zero,
                    widgetSize: _widgetSize ?? Size.zero,
                  ),
                  size: _widgetSize ?? Size.zero,
                ),
            ],
          ),
        );
      },
    );
  }

  void _onHover(PointerEvent event) {
    if (_imageSize == null || _widgetSize == null) return;

    final localPosition = event.localPosition;
    final detection = _findDetectionAtPosition(localPosition);

    setState(() {
      _hoverPosition = localPosition;
      _hoveredDetection = detection;
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _hoverPosition = null;
      _hoveredDetection = null;
    });
  }

  Detection? _findDetectionAtPosition(Offset position) {
    if (_imageSize == null || _widgetSize == null) return null;

    // Calculate scale factors
    final scaleX = _widgetSize!.width / _imageSize!.width;
    final scaleY = _widgetSize!.height / _imageSize!.height;

    for (final detection in widget.detections) {
      // Scale bounding box coordinates
      final left = detection.x * scaleX;
      final top = detection.y * scaleY;
      final width = detection.width * scaleX;
      final height = detection.height * scaleY;

      final rect = Rect.fromLTWH(left, top, width, height);

      if (rect.contains(position)) {
        return detection;
      }
    }
    return null;
  }

  Widget _buildHoverBox() {
    if (_hoveredDetection == null) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getColorForClass(_hoveredDetection!.classId),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hoveredDetection!.className,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Confidence: ${(_hoveredDetection!.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Class ID: ${_hoveredDetection!.classId}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateImageSize() {
    if (_widgetSize == null) return;

    // Get the actual rendered image size
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final imageProvider = FileImage(widget.imageFile);
      imageProvider
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              if (mounted) {
                setState(() {
                  _imageSize = Size(
                    info.image.width.toDouble(),
                    info.image.height.toDouble(),
                  );
                });
              }
            }),
          );
    }
  }

  Color _getColorForClass(int classId) {
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
}

class DetectionBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;
  final Size widgetSize;

  DetectionBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.widgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero || widgetSize == Size.zero) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Calculate scale factors
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;

    for (final detection in detections) {
      // Scale bounding box coordinates
      final left = detection.x * scaleX;
      final top = detection.y * scaleY;
      final width = detection.width * scaleX;
      final height = detection.height * scaleY;

      // Choose color based on class
      final color = _getColorForClass(detection.classId);
      paint.color = color.withOpacity(0.6);

      // Draw bounding box
      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, paint);
    }
  }

  Color _getColorForClass(int classId) {
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
