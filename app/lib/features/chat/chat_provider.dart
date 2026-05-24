import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/scan_result.dart';
import '../../core/models/chat_message.dart';

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [
        ChatMessage(
          role: ChatRole.ai,
          text: '안녕하세요! Green Scanner입니다.\n버리기 애매한 쓰레기의 상태를 말씀해 주시면 정확한 분리배출 방법을 안내해 드릴게요.',
          createdAt: DateTime.now(),
        ),
      ];

  bool get isLoading => state.any((m) => m.isLoading);

  Future<void> sendMessage(String text) async {
    if (isLoading) return;

    state = [
      ...state,
      ChatMessage(role: ChatRole.user, text: text, createdAt: DateTime.now()),
      ChatMessage(role: ChatRole.ai, isLoading: true, createdAt: DateTime.now()),
    ];

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/chat/', data: {'message': text});
      final result = ScanResult.fromJson(res.data as Map<String, dynamic>);
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(role: ChatRole.ai, result: result, createdAt: DateTime.now()),
      ];
    } catch (_) {
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          role: ChatRole.ai,
          text: '분석에 실패했어요. 다시 시도해 주세요.',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);
