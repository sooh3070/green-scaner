import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_colors.dart';
import '../account/account_page.dart';

const _flatIconColor = Color(0xFF4B5563);

const _verdictIcon = {
  '플라스틱': Icons.local_drink_outlined,
  '종이류': Icons.inventory_2_outlined,
  '유리': Icons.wine_bar_outlined,
  '캔': Icons.coffee_outlined,
  '비닐': Icons.shopping_bag_outlined,
  '스티로폼': Icons.inbox_outlined,
  '음식물': Icons.restaurant_outlined,
  '일반쓰레기': Icons.delete_outline_rounded,
  '특수폐기물': Icons.warning_amber_rounded,
  '알수없음': Icons.help_outline_rounded,
};

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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '통계',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            _AccountButton(user: user),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (user != null) ...[
                          _MyStatsCard(user: user),
                          const SizedBox(height: 12),
                        ] else ...[
                          _LoginPromptCard(
                            onLogin: AuthService.signInWithGoogle,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _GlobalStatsCard(),
                        const SizedBox(height: 24),
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

// ─────────────────────────────────────────────
// 계정 버튼
// ─────────────────────────────────────────────
class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () async {
        await Navigator.push<AccountPageResult>(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          if (user!.photoURL != null)
            CircleAvatar(
              backgroundImage: NetworkImage(user!.photoURL!),
              radius: 14,
            )
          else
            const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 6),
          Text(
            user!.displayName?.split(' ').first ?? '사용자',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 로그인 유도 카드
// ─────────────────────────────────────────────
class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard({required this.onLogin});
  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 32, color: _flatIconColor),
          const SizedBox(height: 8),
          const Text(
            '로그인하면 내 분리배출 기여를\n확인할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(
                Icons.login_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text('Google로 로그인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 내 통계 카드
// ─────────────────────────────────────────────
class _MyStatsCard extends StatelessWidget {
  const _MyStatsCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.myScansStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        const recyclableVerdicts = {'플라스틱', '종이류', '유리', '캔', '비닐', '스티로폼'};
        final recyclable = docs
            .where((d) => recyclableVerdicts.contains(d['verdict']))
            .length;
        final trees = (recyclable / 50).floor();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary1,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '내 기여',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.displayName?.split(' ').first ?? '사용자',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.qr_code_scanner_rounded,
                      value: '$total',
                      label: '총 판별',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.recycling_rounded,
                      value: '$recyclable',
                      label: '재활용 성공',
                      color: AppColors.primary1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.park_outlined,
                      value: '$trees',
                      label: '나무 살리기',
                      color: const Color(0xFF2E7D32),
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

// ─────────────────────────────────────────────
// 글로벌 통계 카드
// ─────────────────────────────────────────────
class _GlobalStatsCard extends StatelessWidget {
  const _GlobalStatsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.globalStatsStream(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final totalScans = (data['totalScans'] as num?)?.toInt() ?? 0;
        final recyclableCount = (data['recyclableCount'] as num?)?.toInt() ?? 0;
        final verdictCounts =
            (data['verdictCounts'] as Map<String, dynamic>?) ?? {};

        final sorted = verdictCounts.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));
        final top5 = sorted.take(5).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '전체 통계',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.bar_chart_rounded,
                      value: '$totalScans',
                      label: '총 판별 수',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.recycling_rounded,
                      value: '$recyclableCount',
                      label: '재활용 처리',
                      color: AppColors.primary1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.park_outlined,
                      value: '${(recyclableCount / 50).floor()}',
                      label: '나무 살리기',
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              if (top5.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF2F2F2)),
                const SizedBox(height: 14),
                const Text(
                  'TOP 5 쓰레기 종류',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                ...top5.map((e) {
                  final maxVal = (top5.first.value as num).toDouble();
                  final val = (e.value as num).toDouble();
                  final ratio = maxVal > 0 ? val / maxVal : 0.0;
                  return _VerdictBar(
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

// ─────────────────────────────────────────────
// 작은 통계 박스
// ─────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    this.color = const Color(0xFF1A1A1A),
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: _flatIconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 카테고리 바
// ─────────────────────────────────────────────
class _VerdictBar extends StatelessWidget {
  const _VerdictBar({
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Icon(icon, size: 16, color: _flatIconColor),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFFEEEEEE),
                color: AppColors.primary1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}
