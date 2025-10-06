import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;
  static const _dbName = 'banana_scan.db'; // keep a single source of truth

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("banana_scan.db");
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2, // <- current db version (has image_path)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE disease_detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER,
        disease_name TEXT,
        confidence REAL,
        FOREIGN KEY(scan_id) REFERENCES scans(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> resetDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    await deleteDatabase(path);
    _database = null; // force re-open on next access
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE scans ADD COLUMN image_path TEXT');
    }
  }

  // ---- CRUD ----

  Future<int> insertScan(Scan scan) async {
    final db = await database;
    return await db.insert('scans', scan.toMap());
  }

  Future<int> insertDetection(DiseaseDetection detection) async {
    final db = await database;
    return await db.insert('disease_detections', detection.toMap());
  }

  /// Inserts scan + all detections in a single transaction.
  Future<int> insertScanWithDetections(Scan scan) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      final scanId = await txn.insert(
        'scans',
        scan.toMap(),
      ); // includes image_path
      for (final d in scan.detections) {
        await txn.insert('disease_detections', {
          'scan_id': scanId,
          'disease_name': d.diseaseName,
          'confidence': d.confidence,
        });
      }
      return scanId;
    });
  }

  Future<List<Scan>> getScans() async {
    final db = await database;
    final scanMaps = await db.query('scans', orderBy: 'id DESC');

    List<Scan> scans = [];
    for (var scanMap in scanMaps) {
      final scan = Scan.fromMap(scanMap);
      final detMaps = await db.query(
        'disease_detections',
        where: 'scan_id = ?',
        whereArgs: [scan.id],
      );
      final detections = detMaps
          .map((e) => DiseaseDetection.fromMap(e))
          .toList();
      scans.add(
        Scan(
          id: scan.id,
          date: scan.date,
          imagePath: scan.imagePath, // keep it
          detections: detections,
        ),
      );
    }
    return scans;
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    // cascades to detections with foreign_keys=ON
    return await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }
}

// -------- Summaries for History screen --------

class ScanSummary {
  final int id;
  final String date;
  final int detectionCount;
  final String imagePath;

  ScanSummary({
    required this.id,
    required this.date,
    required this.detectionCount,
    required this.imagePath,
  });
}

extension ScanQueries on DBHelper {
  Future<List<ScanSummary>> getScanSummaries() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.id, s.date, s.image_path, COUNT(d.id) AS detection_count
      FROM scans s
      LEFT JOIN disease_detections d ON d.scan_id = s.id
      GROUP BY s.id
      ORDER BY s.id DESC
    ''');

    return rows.map((r) {
      return ScanSummary(
        id: (r['id'] as int),
        date: (r['date'] as String),
        detectionCount: (r['detection_count'] as int),
        imagePath: (r['image_path'] as String?) ?? '',
      );
    }).toList();
  }
}

// -------- Detail query --------

extension ScanQueriesDetail on DBHelper {
  Future<Scan?> getScanById(int id) async {
    final db = await database;

    final scanRows = await db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (scanRows.isEmpty) return null;

    final detRows = await db.query(
      'disease_detections',
      where: 'scan_id = ?',
      whereArgs: [id],
      orderBy: 'confidence DESC',
    );

    final detections = detRows.map((e) => DiseaseDetection.fromMap(e)).toList();
    final scan = Scan.fromMap(scanRows.first);

    return Scan(
      id: scan.id,
      date: scan.date,
      imagePath: scan.imagePath,
      detections: detections,
    );
  }
}
