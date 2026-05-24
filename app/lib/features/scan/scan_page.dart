import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'scan_provider.dart';
import 'analysis_page.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isCameraReady = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    ref.read(scanProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _capture() async {
    if (!_isCameraReady || _isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final xfile = await _controller!.takePicture();
      if (!mounted) return;

      ref.read(scanProvider.notifier).reset();

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, _) =>
              AnalysisPage(imageFile: File(xfile.path)),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 카메라 프리뷰
          if (_isCameraReady && _controller != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 하단 그라데이션
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),

          // 상단 바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        '카메라 스캔',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // 하단 컨트롤
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _isCapturing
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 64),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: AppColors.primary1, strokeWidth: 3),
                        ],
                      ),
                    )
                  : _CaptureView(onCapture: _capture),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '촬영 버튼을 눌러 분리배출을 확인하세요',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
