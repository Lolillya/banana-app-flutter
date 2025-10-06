// history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/db/models/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = DBHelper().getScanSummaries();
  }

  Future<void> _reload() async {
    setState(() {
      _future = DBHelper().getScanSummaries();
    });
    await _future;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _thumb(String path, int id) {
    final exists = path.isNotEmpty && File(path).existsSync();
    final image = exists
        ? Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover)
        : const Icon(Icons.image_not_supported, size: 28);

    // Nice polish: hero to detail
    return Hero(
      tag: 'scan-thumb-$id',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 56, height: 56, child: Center(child: image)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<ScanSummary>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SizedBox(height: 40),
                    Center(child: Text('No saved scans yet')),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = items[i];
                  return Dismissible(
                    key: ValueKey(s.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete scan?'),
                              content: const Text(
                                'This will remove the scan and its detections.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) async {
                      await DBHelper().deleteScan(s.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deleted scan #${s.id}')),
                      );
                      _reload();
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: _thumb(s.imagePath, s.id),
                        title: Text(
                          'Scan #${s.id}  •  ${_formatDate(s.date)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${s.detectionCount} result(s)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/scan_details',
                            arguments: s.id,
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
