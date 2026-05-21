class ScanResult {
  final String verdict;
  final String? condition;
  final String action;
  final String reason;

  const ScanResult({
    required this.verdict,
    this.condition,
    required this.action,
    required this.reason,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        verdict: json['verdict'] as String,
        condition: json['condition'] as String?,
        action: json['action'] as String,
        reason: json['reason'] as String,
      );
}
