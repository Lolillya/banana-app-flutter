# YOLO Real-Time Detection Setup for Flutter

## Overview

This setup implements real-time object detection using your TensorFlow Lite YOLO model in Flutter. The implementation includes:

- **MLService**: Handles TensorFlow Lite model loading and inference
- **DetectionOverlay**: Renders bounding boxes and labels over camera preview
- **Real-time Detection**: Processes camera frames every 200ms for optimal performance

## Files Created/Modified

### Core Services

- `lib/core/services/ml_service.dart` - Main ML inference service
- `lib/core/widgets/detection_overlay.dart` - Bounding box rendering

### Camera Integration

- `lib/feataures/camera_screen/presentation/camera_screen.dart` - Updated with real-time detection

### Assets

- `assets/models/labels.txt` - Class labels for COCO dataset (modify for your model)
- `assets/models/best_float32.tflite` - Your existing model file

## Key Features

### 1. Real-Time Detection

- Captures frames every 200ms (5 FPS) for optimal performance
- Asynchronous processing to maintain smooth UI
- Toggle detection on/off with floating action button

### 2. YOLO Post-Processing

- Confidence threshold filtering (0.5)
- Non-Maximum Suppression (NMS) with IoU threshold (0.4)
- Proper coordinate scaling from model output to screen coordinates

### 3. Visual Feedback

- Colored bounding boxes for different object classes
- Confidence scores displayed as percentages
- Real-time inference time monitoring
- Detection count and top detections display

### 4. Performance Optimization

- Efficient image preprocessing
- Memory-conscious tensor operations
- Proper resource cleanup and disposal

## Model Requirements

Your TensorFlow Lite model should:

- Accept input shape: `[1, 640, 640, 3]` (RGB images)
- Output shape: `[1, 8400, 85]` for COCO (80 classes + 5 box params)
- Use float32 format
- Follow YOLO output format: `[x, y, w, h, confidence, class_scores...]`

## Customization

### For Your Specific Model

1. **Update class count**: Modify `numClasses` in `ml_service.dart`
2. **Update labels**: Edit `assets/models/labels.txt` with your class names
3. **Adjust input size**: Change `inputSize` if your model uses different dimensions
4. **Tune thresholds**: Adjust `confidenceThreshold` and `iouThreshold` as needed

### Performance Tuning

- **Detection frequency**: Modify timer duration in `_startRealTimeDetection()`
- **Image resolution**: Adjust `ResolutionPreset` in camera controller
- **Batch processing**: Consider processing multiple frames in batch for better throughput

## Usage

1. **Install dependencies**: `flutter pub get`
2. **Place your model**: Ensure `best_float32.tflite` is in `assets/models/`
3. **Update labels**: Modify `labels.txt` to match your model's classes
4. **Run the app**: Navigate to camera screen to see real-time detection

## Controls

- **Green Play Button**: Start/resume real-time detection
- **Red Stop Button**: Pause real-time detection
- **Blue Camera Button**: Navigate to results screen
- **ML Status Indicator**: Shows if model is loaded (green) or loading (red)

## Troubleshooting

### Common Issues

1. **Model not loading**: Check file path and ensure model is in assets
2. **Poor performance**: Reduce detection frequency or image resolution
3. **Incorrect detections**: Verify input preprocessing matches training format
4. **Memory issues**: Ensure proper disposal of resources in `dispose()` methods

### Performance Tips

- Use lower camera resolution for better performance
- Increase detection interval for slower devices
- Consider using quantized models for mobile deployment
- Profile memory usage and optimize tensor operations

## Next Steps

1. **Model Optimization**: Consider using quantized INT8 models for better performance
2. **Custom Training**: Train YOLO model specifically for your use case
3. **Advanced Features**: Add object tracking, detection history, or custom alerts
4. **Platform Optimization**: Use platform-specific optimizations (GPU acceleration)
