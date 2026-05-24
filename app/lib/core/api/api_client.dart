import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final apiKey = dotenv.get('API_KEY', fallback: '');
  return Dio(BaseOptions(
    baseUrl: dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:8000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: apiKey.isNotEmpty ? {'X-API-Key': apiKey} : {},
  ));
});
