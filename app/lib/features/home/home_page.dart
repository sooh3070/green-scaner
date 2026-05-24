import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/scan_history_entry.dart';
import '../scan/scan_page.dart';
import '../chat/chat_page.dart';
import '../kiosk/kiosk_page.dart';
import 'scan_history_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 0;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final historyAsync = ref.watch(scanHistoryProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: _isScrolled
                ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: AppBar(
              backgroundColor: _isScrolled
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Row(
                children: [
                  Image.asset('assets/icon.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  const Text(
                    '그린스캐너',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Iconsax.user, size: 18, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20, topPadding + kToolbarHeight + 8, 20, 0),
        children: [
          const SizedBox(height: 8),
          _HeroBanner(
            onStart: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanPage()),
            ),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('주요 기능'),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Iconsax.camera,
            title: '카메라 스캔 모드',
            subtitle: '사물을 인식해 배출 방법을 분석합니다',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanPage()),
            ),
          ),
          _FeatureCard(
            icon: Iconsax.message,
            title: '채팅 판별 모드',
            subtitle: '애매한 쓰레기는 AI에게 물어보세요',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            ),
          ),
          _FeatureCard(
            icon: Iconsax.scan,
            title: '키오스크 자동 감지',
            subtitle: '센서가 감지되면 자동으로 스캔을 시작합니다',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KioskPage()),
            ),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('최근 스캔 기록'),
          const SizedBox(height: 12),
          historyAsync.when(
            data: (entries) => entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '아직 스캔 기록이 없어요',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ),
                  )
                : Column(
                    children: entries
                        .take(5)
                        .map((e) => _HistoryItem(entry: e))
                        .toList(),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary1, AppColors.primary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '어떻게 버릴지\n망설여지시나요?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '카메라로 촬영하면\nAI가 분리배출 방법을 바로 알려드려요.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '시작하기',
                          style: TextStyle(
                            color: AppColors.primary2,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16, color: AppColors.primary2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.recycling, size: 72, color: Colors.white24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary1, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.entry});

  final ScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = entry.scannedAt;
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.recycling, color: AppColors.primary1, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.result.verdict,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          if (entry.result.condition != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.result.condition!,
                style: const TextStyle(color: AppColors.primary1, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
