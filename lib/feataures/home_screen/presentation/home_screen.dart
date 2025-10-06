import 'package:flutter/material.dart';
import '../../../core/db/models/db_helper.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed the stray const Image() that wasn't used

    Future<void> _confirmAndResetDb() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reset database?'),
          content: const Text(
            'This will delete all scans and detections from local storage.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await DBHelper().resetDatabase();
        // optional: also navigate to history to show it's empty
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset complete')),
        );
      }
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: const [
                  Image(image: AssetImage("assets/logo.png")),
                  SizedBox(height: 8),
                  Text("AI leaf scans for banana health"),
                ],
              ),
              const ScanSummaryCard(), // your custom history card
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/yolo");
                      },
                      child: const Text("Start"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _confirmAndResetDb,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Reset Database'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanSummaryCard extends StatefulWidget {
  const ScanSummaryCard({super.key});

  @override
  State<ScanSummaryCard> createState() => _ScanSummaryCardState();
}

class _ScanSummaryCardState extends State<ScanSummaryCard> {
  int totalResults = 0;
  String lastScanTime = "No scans yet";

  @override
  void initState() {
    super.initState();
    _loadScanSummary();
  }

  Future<void> _loadScanSummary() async {
    final db = DBHelper();
    final scans = await db.getScans();

    if (scans.isNotEmpty) {
      setState(() {
        totalResults = scans.length;

        // last scan is first because getScans() orders by id DESC
        final lastDate = DateTime.tryParse(scans.first.date);
        if (lastDate != null) {
          lastScanTime = _formatTimeAgo(lastDate);
        }
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hrs ago";
    } else {
      return DateFormat('MMM d, yyyy – hh:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(width: 1.0, color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
        ),
        onPressed: () => Navigator.pushNamed(context, '/history'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Inspection Results",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("$totalResults Results"),
                  const SizedBox(height: 4),
                  Text(lastScanTime),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
