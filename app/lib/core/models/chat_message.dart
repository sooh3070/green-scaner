import 'scan_result.dart';

enum ChatRole { user, ai }

class ChatMessage {
  final ChatRole role;
  final String? text;
  final ScanResult? result;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    required this.role,
    this.text,
    this.result,
    required this.createdAt,
    this.isLoading = false,
  });
}
