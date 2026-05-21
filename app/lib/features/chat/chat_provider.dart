import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/scan_result.dart';

class ChatNotifier extends AsyncNotifier<ScanResult?> {
  @override
  Future<ScanResult?> build() async => null;

  Future<void> sendMessage(String text) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/chat/', data: {'text': text});
      return ScanResult.fromJson(res.data as Map<String, dynamic>);
    });
  }

  void reset() => state = const AsyncData(null);
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, ScanResult?>(ChatNotifier.new);
