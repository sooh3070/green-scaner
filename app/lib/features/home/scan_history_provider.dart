import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/scan_history_entry.dart';
import '../../core/services/scan_history_service.dart';

class ScanHistoryNotifier extends AsyncNotifier<List<ScanHistoryEntry>> {
  @override
  Future<List<ScanHistoryEntry>> build() => ScanHistoryService.load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ScanHistoryService.load());
  }
}

final scanHistoryProvider =
    AsyncNotifierProvider<ScanHistoryNotifier, List<ScanHistoryEntry>>(
        ScanHistoryNotifier.new);
