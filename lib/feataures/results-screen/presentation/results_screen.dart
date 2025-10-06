import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo/yolo_result.dart';

import '../../../core/db/models/db_helper.dart';
import '../../../core/db/models/db_model.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Future<String> _persistImage(String tmpPath) async {
    // Copy the temp image into app documents so it’s not cleaned up by the OS
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.png';
    final newPath = '${dir.path}/$fileName';
    await File(tmpPath).copy(newPath);
    return newPath;
  }

  Future<void> _saveResults(
    BuildContext context, {
    required String imagePath,
    required List<YOLOResult> results,
  }) async {
    if (results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No detections to save')));
      return;
    }

    try {
      final persistedPath = await _persistImage(imagePath);
      final dateStr = DateTime.now().toIso8601String();

      final detections = results.map((r) {
        return DiseaseDetection(
          id: null,
          scanId: 0, // placeholder; real id assigned in transaction
          diseaseName: (r.className ?? 'Unknown').trim(),
          confidence: r.confidence,
        );
      }).toList();

      final scan = Scan(
        date: dateStr,
        imagePath: persistedPath, // <-- REQUIRED now
        detections: detections,
      );

      final scanId = await DBHelper().insertScanWithDetections(scan);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved scan #$scanId with ${detections.length} detections',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    // Expecting: { 'imagePath': String, 'results': List<YOLOResult> }
    if (args is! Map) {
      return const Scaffold(
        body: Center(child: Text('Invalid arguments passed to ResultsScreen')),
      );
    }

    final String imagePath = args['imagePath'] as String? ?? '';
    final List<YOLOResult> results = (args['results'] as List)
        .cast<YOLOResult>();

    return Scaffold(
      appBar: AppBar(title: const Text("Detection Results")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Captured photo
            if (imagePath.isNotEmpty && File(imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  height: 220,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            const SizedBox(height: 12),

            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(Icons.sick_outlined),
                    SizedBox(width: 8),
                    Text('Disease'),
                  ],
                ),
                Text("Confidence"),
              ],
            ),
            const Divider(),

            // List of results
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text("No objects detected"))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final r = results[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r.className ?? "Unknown"),
                              Text(
                                "${(r.confidence * 100).toStringAsFixed(1)}%",
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text('Recapture'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: imagePath.isEmpty
                        ? null
                        : () => _saveResults(
                            context,
                            imagePath: imagePath,
                            results: results,
                          ),
                    icon: const Icon(Icons.check, size: 28),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
