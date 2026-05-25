import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/eco_grade_avatar.dart';
import '../../core/models/scan_history_entry.dart';
import '../account/account_page.dart';
import '../scan/scan_page.dart';
import '../chat/chat_page.dart';
import '../kiosk/kiosk_page.dart';
import 'scan_history_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.onOpenStats});

  final VoidCallback onOpenStats;

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
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<AccountPageResult>(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountPage()),
                      );
                      if (!context.mounted) return;
                      if (result == AccountPageResult.openStats) {
                        widget.onOpenStats();
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const EcoGradeAvatar(radius: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          20,
          topPadding + kToolbarHeight + 8,
          20,
          0,
        ),
        children: [
          const SizedBox(height: 8),
          _HeroBanner(
            onStart: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanPage()),
            ).then((_) => ref.invalidate(scanHistoryProvider)),
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
            ).then((_) => ref.invalidate(scanHistoryProvider)),
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
          const _SectionTitle('내 에코 활동'),
          const SizedBox(height: 12),
          _EcoActivitySection(
            onOpenAccount: () async {
              final result = await Navigator.push<AccountPageResult>(
                context,
                MaterialPageRoute(builder: (_) => const AccountPage()),
              );
              if (!context.mounted) return;
              if (result == AccountPageResult.openStats) widget.onOpenStats();
            },
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
            error: (error, stackTrace) => const SizedBox.shrink(),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
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
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primary2,
                        ),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
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
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

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
            child: const Icon(
              Icons.recycling,
              color: AppColors.primary1,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.result.verdict,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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

// ─── Eco activity section ─────────────────────

class _EcoActivitySection extends StatelessWidget {
  const _EcoActivitySection({required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.userStream,
      initialData: AuthService.currentUser,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return _EcoLockedCard();
        return _EcoMiniCard(onOpenAccount: onOpenAccount);
      },
    );
  }
}

// 로그인 상태: 실제 데이터 표시
class _EcoMiniCard extends StatelessWidget {
  const _EcoMiniCard({required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.myScansStream(),
      builder: (context, snap) {
        final docs     = snap.data?.docs ?? [];
        final total    = docs.length;
        final grade    = getEcoGrade(total);
        final isMax    = grade.maxScans == -1;
        final progress = isMax
            ? 1.0
            : (total - grade.minScans) / (grade.maxScans + 1 - grade.minScans);
        final co2 = docs.fold<double>(
          0,
          (acc, d) => acc + (co2PerVerdict[d['verdict'] as String? ?? ''] ?? 0),
        );
        final gradientStart = Color.lerp(grade.color, Colors.white, 0.25)!;

        return GestureDetector(
          onTap: onOpenAccount,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, grade.color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: grade.color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(grade.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          '에코 등급',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${co2.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'CO₂ 절감',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 $total회 스캔',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      isMax ? '최고 등급 달성! 🎉' : '다음 등급까지 ${grade.maxScans + 1 - total}회',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 비로그인 상태: 잠금 프리뷰
class _EcoLockedCard extends StatelessWidget {
  const _EcoLockedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌱🌳🌍', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '에코 등급이 기다리고 있어요',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '분리배출할수록 올라가는 나만의 환경 점수',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _LockedBadge(label: 'CO₂ 절감량'),
              const SizedBox(width: 8),
              _LockedBadge(label: '에코 등급'),
              const SizedBox(width: 8),
              _LockedBadge(label: '재활용률'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: AuthService.signInWithGoogle,
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Google로 로그인하고 확인하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBadge extends StatelessWidget {
  const _LockedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary1.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.primary1),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
