// db_model.dart
class Scan {
  final int? id;
  final String date;
  final String imagePath; // <-- add this
  final List<DiseaseDetection> detections;

  Scan({
    this.id,
    required this.date,
    required this.imagePath,
    this.detections = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'image_path': imagePath, // <-- add this
    };
  }

  factory Scan.fromMap(Map<String, dynamic> map) {
    return Scan(
      id: map['id'],
      date: map['date'],
      imagePath: map['image_path'] ?? '', // <-- add this
    );
  }
}

class DiseaseDetection {
  final int? id;
  final int scanId;
  final String diseaseName;
  final double confidence;

  DiseaseDetection({
    this.id,
    required this.scanId,
    required this.diseaseName,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_id': scanId,
      'disease_name': diseaseName,
      'confidence': confidence,
    };
  }

  factory DiseaseDetection.fromMap(Map<String, dynamic> map) {
    return DiseaseDetection(
      id: map['id'],
      scanId: map['scan_id'],
      diseaseName: map['disease_name'],
      confidence: map['confidence'],
    );
  }
}
