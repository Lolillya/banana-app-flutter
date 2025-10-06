import 'package:banana_app/feataures/history-screen/presentation/history_screen.dart';
import 'package:banana_app/feataures/results-screen/presentation/results_screen.dart';
import 'package:banana_app/feataures/home_screen/presentation/home_screen.dart';
import 'package:banana_app/feataures/camera_screen/presentation/camera_screen.dart';
import 'package:banana_app/feataures/scan_details/presentation/scan_details.dart';
import 'package:banana_app/feataures/yolo_screen/presentation/yolo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final cameras = await availableCameras();
  runApp(MainApp(cameras: cameras));
}

class MainApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MainApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Banana App",
      initialRoute: "/",
      routes: {
        "/": (context) => const HomeScreen(),
        "/camera": (context) => CameraScreen(),
        "/results": (context) => ResultsScreen(),
        "/history": (context) => HistoryScreen(),
        "/yolo": (context) => CameraDetectionScreen(),
        "/scan_details": (context) => ScanDetailScreen(),
      },
    );
  }
}
