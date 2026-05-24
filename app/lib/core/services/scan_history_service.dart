import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history_entry.dart';
import '../models/scan_result.dart';

const _kHistoryKey = 'scan_history';
const _kMaxEntries = 20;

class ScanHistoryService {
  static Future<List<ScanHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    if (raw == null) return [];
    try {
      return ScanHistoryEntry.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await load();
    entries.insert(0, ScanHistoryEntry(result: result, scannedAt: DateTime.now()));
    final trimmed = entries.take(_kMaxEntries).toList();
    await prefs.setString(_kHistoryKey, ScanHistoryEntry.encodeList(trimmed));
  }
}
