import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/scan_result.dart';

class ScanNotifier extends AsyncNotifier<ScanResult?> {
  @override
  Future<ScanResult?> build() async => null;

  Future<void> scanImage(File image) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
      });
      final res = await dio.post('/scan/', data: formData);
      return ScanResult.fromJson(res.data as Map<String, dynamic>);
    });
  }

  void reset() => state = const AsyncData(null);
}

final scanProvider =
    AsyncNotifierProvider<ScanNotifier, ScanResult?>(ScanNotifier.new);
