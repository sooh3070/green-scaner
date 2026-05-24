import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide ScanResult;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/scan_result.dart';
import '../../core/theme/app_colors.dart';
import 'kiosk_result_page.dart';

const _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const _charUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

class KioskPage extends ConsumerStatefulWidget {
  const KioskPage({super.key});

  @override
  ConsumerState<KioskPage> createState() => _KioskPageState();
}

enum _BleStatus { scanning, connecting, connected }

class _KioskPageState extends ConsumerState<KioskPage> {
  _BleStatus _bleStatus = _BleStatus.scanning;
  BluetoothDevice? _device;
  StreamSubscription? _scanSub;
  StreamSubscription? _notifySub;
  StreamSubscription? _connSub;

  CameraController? _camera;
  bool _cameraReady = false;
  bool _triggering = false;
  int _countdownSeconds = 30;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    if (!mounted) return;
    setState(() => _bleStatus = _BleStatus.scanning);

    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == 'GreenScanner') {
          FlutterBluePlus.stopScan();
          _scanSub?.cancel();
          _connect(r.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (!mounted) return;
    setState(() {
      _bleStatus = _BleStatus.connecting;
      _device = device;
    });

    try {
      await device.connect(autoConnect: false);

      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && mounted) {
          _notifySub?.cancel();
          _disposeCamera();
          setState(() => _bleStatus = _BleStatus.scanning);
          _startScan();
        }
      });

      final services = await device.discoverServices();
      for (final s in services) {
        if (s.serviceUuid.toString().toLowerCase() == _serviceUuid) {
          for (final c in s.characteristics) {
            if (c.characteristicUuid.toString().toLowerCase() == _charUuid) {
              await c.setNotifyValue(true);
              _notifySub = c.onValueReceived.listen((value) {
                final msg = String.fromCharCodes(value);
                if (msg == 'TRIGGER') _onTrigger();
              });
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() => _bleStatus = _BleStatus.connected);
        _initCamera();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _bleStatus = _BleStatus.scanning);
        _startScan();
      }
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty || !mounted) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
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
      _camera = controller;
      _cameraReady = true;
    });
  }

  void _disposeCamera() {
    _camera?.dispose();
    _camera = null;
    if (mounted) setState(() => _cameraReady = false);
  }

  Future<void> _onTrigger() async {
    if (_triggering || !_cameraReady || !mounted) return;
    setState(() => _triggering = true);

    try {
      final xfile = await _camera!.takePicture();
      setState(() => _capturedImage = File(xfile.path));

      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/scan/',
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(xfile.path),
        }),
      );
      final result = ScanResult.fromJson(res.data as Map<String, dynamic>);

      _disposeCamera();
      setState(() => _capturedImage = null);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KioskResultPage(
            result: result,
            countdownSeconds: _countdownSeconds,
          ),
        ),
      );

      if (mounted) _initCamera();
    } catch (_) {
      if (mounted) setState(() => _triggering = false);
    } finally {
      if (mounted) setState(() => _triggering = false);
    }
  }

  void _showSettings() {
    int tempSeconds = _countdownSeconds;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '키오스크 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '결과 화면 유지 시간',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$tempSeconds초',
                      style: const TextStyle(
                        color: AppColors.primary1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: tempSeconds.toDouble(),
                min: 10,
                max: 60,
                divisions: 10,
                activeColor: AppColors.primary1,
                onChanged: (v) => setModal(() => tempSeconds = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10초',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12)),
                  Text('60초',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '감지 거리: 30cm 이내 (고정)',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _countdownSeconds = tempSeconds);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _notifySub?.cancel();
    _connSub?.cancel();
    _device?.disconnect();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _bleStatus == _BleStatus.connected;

    return Scaffold(
      backgroundColor: connected ? Colors.black : Colors.white,
      extendBodyBehindAppBar: connected,
      appBar: AppBar(
        backgroundColor: connected ? Colors.transparent : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '키오스크 모드',
          style: TextStyle(color: connected ? Colors.white : Colors.black),
        ),
        iconTheme:
            IconThemeData(color: connected ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded,
                color: connected ? Colors.white : Colors.black),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: connected ? _buildCameraView() : _buildStatusView(),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_triggering && _capturedImage != null)
          Positioned.fill(
            child: Image.file(_capturedImage!, fit: BoxFit.cover),
          )
        else if (_cameraReady && _camera != null)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _camera!.value.previewSize!.height,
                height: _camera!.value.previewSize!.width,
                child: CameraPreview(_camera!),
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
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),

        // 하단 안내 문구
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Text(
                _triggering
                    ? '촬영 중...'
                    : '물체가 가까이 다가오면 자동으로 촬영 후 스캔이 시작돼요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),

        // 분석 중 오버레이 (반투명 모달)
        if (_triggering)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                      SizedBox(height: 16),
                      Text(
                        'AI 분석 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary1.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary1,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _bleStatus == _BleStatus.scanning
                  ? 'GreenScanner 검색 중'
                  : '기기 연결 중...',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _bleStatus == _BleStatus.scanning
                  ? 'ESP32 기기를 찾고 있습니다.'
                  : 'GreenScanner에 연결하고 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
