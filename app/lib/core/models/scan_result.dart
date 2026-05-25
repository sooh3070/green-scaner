class ScanResult {
  final String verdict;
  final String? condition;
  final int pollution;
  final String action;
  final String reason;

  const ScanResult({
    required this.verdict,
    this.condition,
    required this.pollution,
    required this.action,
    required this.reason,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        verdict: json['verdict'] as String,
        condition: json['condition'] as String?,
        pollution: (json['pollution'] as num?)?.toInt() ?? 0,
        action: json['action'] as String,
        reason: json['reason'] as String,
      );
}
