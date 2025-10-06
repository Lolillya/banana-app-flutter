import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/db/models/db_helper.dart';
import '../../../core/db/models/db_model.dart';

class ScanDetailScreen extends StatefulWidget {
  const ScanDetailScreen({super.key});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late int _scanId;
  late Future<Scan?> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    _scanId = (args is int) ? args : int.parse(args.toString());
    _future = DBHelper().getScanById(_scanId);
  }

  Future<void> _reload() async {
    setState(() => _future = DBHelper().getScanById(_scanId));
    await _future;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text('This will remove the scan and its detections.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper().deleteScan(_scanId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted scan #$_scanId')));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan #$_scanId'),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<Scan?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [Text('Error: ${snapshot.error}')],
                );
              }
              final scan = snapshot.data;
              if (scan == null) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [Text('Scan not found')],
                );
              }

              final items = scan.detections;
              final hasImage =
                  scan.imagePath.isNotEmpty &&
                  File(scan.imagePath).existsSync();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (hasImage)
                    Hero(
                      tag: 'scan-thumb-${scan.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(scan.imagePath),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
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
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(_formatDate(scan.date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Detections (${items.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('No detections stored for this scan'),
                      ),
                    )
                  else
                    ...items.map(
                      (d) => Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.sick_outlined),
                          title: Text(d.diseaseName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: d.confidence.clamp(0.0, 1.0),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(d.confidence * 100).toStringAsFixed(1)}% confidence',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
