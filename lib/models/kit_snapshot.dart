import 'dart:convert';
import 'bow_specifications.dart';
import 'arrow_specifications.dart';

/// A snapshot of kit configuration at a point in time
/// Captures the exact bow and arrow setup when a notable score was achieved
class KitSnapshot {
  final String id;
  final String? sessionId;
  final String? bowId;
  final String? quiverId;
  final DateTime snapshotDate;
  final int? score;
  final int? maxScore;
  final String? roundName;
  final String? reason; // 'top_20', 'personal_best', 'manual'

  // Snapshot of bow settings at time of capture
  final String? bowName;
  final String? bowType;
  final BowSpecifications? bowSpecs;

  // Snapshot of quiver/arrow settings at time of capture
  final String? quiverName;
  final ArrowSpecifications? arrowSpecs;

  // User notes
  final String? notes;

  KitSnapshot({
    required this.id,
    this.sessionId,
    this.bowId,
    this.quiverId,
    required this.snapshotDate,
    this.score,
    this.maxScore,
    this.roundName,
    this.reason,
    this.bowName,
    this.bowType,
    this.bowSpecs,
    this.quiverName,
    this.arrowSpecs,
    this.notes,
  });

  /// Serialize to JSON for database storage
  String toJson() {
    return json.encode({
      'id': id,
      'sessionId': sessionId,
      'bowId': bowId,
      'quiverId': quiverId,
      'snapshotDate': snapshotDate.toIso8601String(),
      'score': score,
      'maxScore': maxScore,
      'roundName': roundName,
      'reason': reason,
      'bowName': bowName,
      'bowType': bowType,
      'bowSpecs': bowSpecs?.toMap(),
      'quiverName': quiverName,
      'arrowSpecs': arrowSpecs?.toMap(),
      'notes': notes,
    });
  }

  /// Deserialize from JSON
  factory KitSnapshot.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return KitSnapshot.fromMap(map);
  }

  factory KitSnapshot.fromMap(Map<String, dynamic> map) {
    return KitSnapshot(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String?,
      bowId: map['bowId'] as String?,
      quiverId: map['quiverId'] as String?,
      snapshotDate: DateTime.parse(map['snapshotDate'] as String),
      score: map['score'] as int?,
      maxScore: map['maxScore'] as int?,
      roundName: map['roundName'] as String?,
      reason: map['reason'] as String?,
      bowName: map['bowName'] as String?,
      bowType: map['bowType'] as String?,
      bowSpecs: map['bowSpecs'] != null
          ? BowSpecifications.fromMap(map['bowSpecs'] as Map<String, dynamic>)
          : null,
      quiverName: map['quiverName'] as String?,
      arrowSpecs: map['arrowSpecs'] != null
          ? ArrowSpecifications.fromMap(map['arrowSpecs'] as Map<String, dynamic>)
          : null,
      notes: map['notes'] as String?,
    );
  }

  /// Get percentage score
  double? get percentage {
    if (score == null || maxScore == null || maxScore == 0) return null;
    return (score! / maxScore!) * 100;
  }

  /// Get display text for the reason
  String get reasonDisplay {
    switch (reason) {
      case 'top_20':
        return 'Top 20% Score';
      case 'personal_best':
        return 'Personal Best';
      case 'manual':
        return 'Manual Save';
      default:
        return 'Kit Snapshot';
    }
  }

  /// Check if this snapshot has bow data
  bool get hasBowData =>
      bowName != null || (bowSpecs?.hasAnySpecs ?? false);

  /// Check if this snapshot has arrow data
  bool get hasArrowData =>
      quiverName != null || (arrowSpecs?.hasAnySpecs ?? false);

  /// Check if this snapshot has any equipment data
  bool get hasEquipmentData => hasBowData || hasArrowData;

  KitSnapshot copyWith({
    String? id,
    String? sessionId,
    String? bowId,
    String? quiverId,
    DateTime? snapshotDate,
    int? score,
    int? maxScore,
    String? roundName,
    String? reason,
    String? bowName,
    String? bowType,
    BowSpecifications? bowSpecs,
    String? quiverName,
    ArrowSpecifications? arrowSpecs,
    String? notes,
  }) {
    return KitSnapshot(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      bowId: bowId ?? this.bowId,
      quiverId: quiverId ?? this.quiverId,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      roundName: roundName ?? this.roundName,
      reason: reason ?? this.reason,
      bowName: bowName ?? this.bowName,
      bowType: bowType ?? this.bowType,
      bowSpecs: bowSpecs ?? this.bowSpecs,
      quiverName: quiverName ?? this.quiverName,
      arrowSpecs: arrowSpecs ?? this.arrowSpecs,
      notes: notes ?? this.notes,
    );
  }
}
