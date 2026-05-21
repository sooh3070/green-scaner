import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ESP32가 보내는 BLE 서비스/특성 UUID (펌웨어와 맞춰야 함)
const _kServiceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
const _kCharUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

/// true 가 방출되면 자동 촬영 트리거
final kioskTriggerProvider = StreamProvider<bool>((ref) async* {
  // BLE 스캔 시작
  FlutterBluePlus.startScan(timeout: const Duration(seconds: 0));

  await for (final results in FlutterBluePlus.scanResults) {
    for (final r in results) {
      if (r.device.advName.contains('GreenScanner')) {
        FlutterBluePlus.stopScan();

        final device = r.device;
        await device.connect(autoConnect: false);

        final services = await device.discoverServices();
        for (final svc in services) {
          if (svc.uuid.toString() == _kServiceUuid) {
            for (final char in svc.characteristics) {
              if (char.uuid.toString() == _kCharUuid) {
                await char.setNotifyValue(true);
                await for (final value in char.onValueReceived) {
                  // 0x01 = 트리거 신호
                  if (value.isNotEmpty && value[0] == 0x01) {
                    yield true;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
});
