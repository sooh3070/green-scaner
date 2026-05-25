import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/eco_grade_avatar.dart';
import '../account/account_page.dart';

const _verdictIcon = {
  '플라스틱': Icons.local_drink_outlined,
  '종이류':   Icons.inventory_2_outlined,
  '유리':     Icons.wine_bar_outlined,
  '캔':       Icons.coffee_outlined,
  '비닐':     Icons.shopping_bag_outlined,
  '스티로폼': Icons.inbox_outlined,
  '음식물':   Icons.restaurant_outlined,
  '일반쓰레기': Icons.delete_outline_rounded,
  '특수폐기물': Icons.warning_amber_rounded,
};

// ─── 숫자 카운팅 애니메이션 ───────────────────

class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter({
    required this.value,
    required this.style,
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

class _AnimatedDecimalCounter extends StatelessWidget {
  const _AnimatedDecimalCounter({
    required this.value,
    required this.style,
    this.suffix = '',
  });

  final double value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.toStringAsFixed(1)}$suffix', style: style),
    );
  }
}

// ─── Page ─────────────────────────────────────

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: AuthService.userStream,
          initialData: AuthService.currentUser,
          builder: (context, authSnap) {
            final user = authSnap.data;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(user: user),
                        const SizedBox(height: 20),
                        if (user != null) ...[
                          _MyStatsCard(user: user),
                          const SizedBox(height: 14),
                        ] else ...[
                          _LoginPromptCard(onLogin: AuthService.signInWithGoogle),
                          const SizedBox(height: 14),
                        ],
                        _GlobalStatsCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── 헤더 ─────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '통계',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        if (user != null)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const EcoGradeAvatar(radius: 15),
                const SizedBox(width: 6),
                Text(
                  user!.displayName?.split(' ').first ?? '사용자',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFFBBBBBB)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 로그인 유도 카드 ──────────────────────────

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard({required this.onLogin});
  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 34, color: AppColors.primary1),
          const SizedBox(height: 10),
          const Text(
            '로그인하면 내 분리배출 기여도를\n한눈에 확인할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded, size: 17, color: Colors.white),
              label: const Text('Google로 로그인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 내 통계 카드 ──────────────────────────────

class _MyStatsCard extends StatelessWidget {
  const _MyStatsCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.myScansStream(),
      builder: (context, snap) {
        final docs       = snap.data?.docs ?? [];
        final total      = docs.length;
        const recyclableVerdicts = {'플라스틱', '종이류', '유리', '캔', '비닐', '스티로폼'};
        final recyclable = docs.where((d) => recyclableVerdicts.contains(d['verdict'])).length;
        final rate       = total == 0 ? 0 : (recyclable / total * 100).round();
        final co2kg      = docs.fold<double>(0, (acc, d) {
          final v = d['verdict'] as String? ?? '';
          return acc + (co2PerVerdict[v] ?? 0);
        });

        return Container(
          padding: const EdgeInsets.all(20),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary1,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      '내 기여',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.displayName?.split(' ').first ?? '사용자',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 메인 숫자 (총 스캔) - 크게 표시
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedCounter(
                    value: total,
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 6),
                    child: Text(
                      '회 판별',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFF2F2F2)),
              const SizedBox(height: 18),
              // 3개 세부 통계
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.recycling_rounded,
                      iconColor: AppColors.primary1,
                      value: recyclable,
                      label: '재활용 성공',
                    ),
                  ),
                  _Divider(),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.percent_rounded,
                      iconColor: const Color(0xFF1565C0),
                      value: rate,
                      label: '재활용률',
                      suffix: '%',
                    ),
                  ),
                  _Divider(),
                  Expanded(
                    child: _Co2StatTile(
                      icon: Icons.co2_outlined,
                      iconColor: const Color(0xFF2E7D32),
                      co2kg: co2kg,
                      label: 'CO₂ 절감',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 52, color: const Color(0xFFF2F2F2));
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.suffix = '',
  });

  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        _AnimatedCounter(
          value: value,
          suffix: suffix,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }
}

class _Co2StatTile extends StatelessWidget {
  const _Co2StatTile({
    required this.icon,
    required this.iconColor,
    required this.co2kg,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final double co2kg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        _AnimatedDecimalCounter(
          value: co2kg,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
          ),
          suffix: 'kg',
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }
}

// ─── 전체 통계 카드 ────────────────────────────

class _GlobalStatsCard extends StatelessWidget {
  const _GlobalStatsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.globalStatsStream(),
      builder: (context, snap) {
        final data           = snap.data?.data() ?? {};
        final totalScans     = (data['totalScans'] as num?)?.toInt() ?? 0;
        final recyclableCount = (data['recyclableCount'] as num?)?.toInt() ?? 0;
        final verdictCounts  = (data['verdictCounts'] as Map<String, dynamic>?) ?? {};

        final sorted = verdictCounts.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));
        final top5 = sorted.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(20),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      '전체 통계',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '모든 사용자 기여 합산',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 총 스캔 수 메인 표시
              Row(
                children: [
                  Expanded(
                    child: _GlobalStatBox(
                      label: '총 판별 수',
                      value: totalScans,
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GlobalStatBox(
                      label: '재활용 처리',
                      value: recyclableCount,
                      icon: Icons.recycling_rounded,
                      color: AppColors.primary1,
                    ),
                  ),
                ],
              ),
              if (top5.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF2F2F2)),
                const SizedBox(height: 18),
                const Text(
                  'TOP 5 쓰레기 종류',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 14),
                ...top5.map((e) {
                  final maxVal = (top5.first.value as num).toDouble();
                  final val    = (e.value as num).toDouble();
                  final ratio  = maxVal > 0 ? val / maxVal : 0.0;
                  return _AnimatedVerdictBar(
                    icon: _verdictIcon[e.key] ?? Icons.inventory_2_outlined,
                    label: e.key,
                    count: val.toInt(),
                    ratio: ratio,
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GlobalStatBox extends StatelessWidget {
  const _GlobalStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimatedCounter(
                  value: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 애니메이션 바 ─────────────────────────────

class _AnimatedVerdictBar extends StatelessWidget {
  const _AnimatedVerdictBar({
    required this.icon,
    required this.label,
    required this.count,
    required this.ratio,
  });

  final IconData icon;
  final String label;
  final int count;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Icon(icon, size: 15, color: const Color(0xFF757575)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: _AnimatedCounter(
              value: count,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
