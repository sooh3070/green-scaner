import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'scan_provider.dart';
import 'widgets/result_card.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
    ref.read(scanProvider.notifier).reset();
  }

  Future<void> _scan() async {
    if (_image == null) return;
    await ref.read(scanProvider.notifier).scanImage(_image!);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('분리배출 판별')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImagePreview(image: _image, onPickImage: _pickImage),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _image == null || scanState.isLoading ? null : _scan,
                icon: scanState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(scanState.isLoading ? '분석 중...' : '판별하기'),
              ),
              const SizedBox(height: 24),
              scanState.when(
                data: (result) =>
                    result != null ? ResultCard(result: result) : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => _ErrorBanner(message: e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.onPickImage});

  final File? image;
  final void Function(ImageSource) onPickImage;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: image != null
            ? Image.file(image!, fit: BoxFit.cover)
            : Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => onPickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('카메라'),
                        ),
                        TextButton.icon(
                          onPressed: () => onPickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('갤러리'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(message, style: TextStyle(color: Colors.red[700])),
    );
  }
}
