import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';

class KioskPage extends StatelessWidget {
  const KioskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('키오스크 모드'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary1.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.scan, size: 40, color: AppColors.primary1),
            ),
            const SizedBox(height: 24),
            const Text(
              'ESP32 연결 대기 중',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'GreenScanner 기기가 감지되면\n자동으로 스캔을 시작합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
