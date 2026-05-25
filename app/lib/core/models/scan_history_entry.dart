import 'dart:convert';
import 'scan_result.dart';

class ScanHistoryEntry {
  final ScanResult result;
  final DateTime scannedAt;

  const ScanHistoryEntry({required this.result, required this.scannedAt});

  Map<String, dynamic> toJson() => {
        'verdict': result.verdict,
        'condition': result.condition,
        'pollution': result.pollution,
        'action': result.action,
        'reason': result.reason,
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        result: ScanResult(
          verdict: json['verdict'] as String,
          condition: json['condition'] as String?,
          pollution: (json['pollution'] as num?)?.toInt() ?? 0,
          action: json['action'] as String,
          reason: json['reason'] as String,
        ),
        scannedAt: DateTime.parse(json['scannedAt'] as String),
      );

  static String encodeList(List<ScanHistoryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<ScanHistoryEntry> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ScanHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
