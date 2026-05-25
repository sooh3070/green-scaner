import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/eco_grade.dart';

export '../../core/utils/eco_grade.dart';

enum AccountPageResult { openStats }

double _calcCo2(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  double total = 0;
  for (final doc in docs) {
    total += co2PerVerdict[doc['verdict'] as String? ?? ''] ?? 0;
  }
  return total;
}

// ─── Page ─────────────────────────────────────

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isSigningIn  = false;
  bool _isSigningOut = false;
  bool _isDeleting   = false;

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);
    try {
      await AuthService.signInWithGoogle();
    } catch (_) {
      if (!mounted) return;
      _showSnack('로그인에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await AuthService.signOut();
      if (!mounted) return;
      _showSnack('로그아웃되었습니다.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showSnack('로그아웃에 실패했어요.');
      setState(() => _isSigningOut = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showDeleteDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await AuthService.deleteAccount();
      if (!mounted) return;
      _showSnack('탈퇴가 완료되었습니다.');
      Navigator.pop(context);
    } on NeedsReauthException {
      if (!mounted) return;
      _showSnack('보안을 위해 재로그인 후 다시 시도해주세요.');
      await AuthService.signOut();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showSnack('탈퇴 처리 중 오류가 발생했어요.');
      setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _showDeleteDialog() => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '정말 탈퇴하시겠어요?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: const Text(
            '탈퇴하면 모든 스캔 기록과\n에코 등급이 영구적으로 삭제됩니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소', style: TextStyle(color: Color(0xFF888888))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
              child: const Text('탈퇴하기', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 프로필',
          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: AuthService.userStream,
        initialData: AuthService.currentUser,
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) {
            return _SignedOutView(onSignIn: _signIn, isBusy: _isSigningIn);
          }
          return _SignedInView(
            user: user,
            isSigningOut: _isSigningOut,
            isDeleting: _isDeleting,
            onSignOut: _signOut,
            onDeleteAccount: _deleteAccount,
          );
        },
      ),
    );
  }
}

// ─── Signed-out view ──────────────────────────

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.onSignIn, required this.isBusy});

  final Future<void> Function() onSignIn;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Iconsax.user, size: 42, color: Color(0xFFBDBDBD)),
            ),
            const SizedBox(height: 22),
            const Text(
              '로그인이 필요해요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              '로그인하면 나의 에코 등급과\n분리배출 기여도를 확인할 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.65),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onSignIn,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Iconsax.login, size: 18),
                label: Text(isBusy ? '로그인 중...' : 'Google로 로그인'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary1,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Signed-in view ───────────────────────────

class _SignedInView extends StatelessWidget {
  const _SignedInView({
    required this.user,
    required this.isSigningOut,
    required this.isDeleting,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final User user;
  final bool isSigningOut;
  final bool isDeleting;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.myScansStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final total      = docs.length;
        final recyclable = docs.where((d) => d['recyclable'] == true).length;
        final co2        = _calcCo2(docs);
        final grade      = getEcoGrade(total);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            _ProfileCard(user: user, grade: grade),
            const SizedBox(height: 14),
            _EcoGradeCard(grade: grade, total: total, co2: co2),
            const SizedBox(height: 12),
            _StatsRow(total: total, recyclable: recyclable),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _SettingsButton(
                    icon: Iconsax.logout,
                    label: '로그아웃',
                    isLoading: isSigningOut,
                    disabled: isDeleting,
                    onTap: onSignOut,
                    color: const Color(0xFFE53935),
                    borderColor: const Color(0xFFFFCDD2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SettingsButton(
                    icon: Iconsax.trash,
                    label: '회원탈퇴',
                    isLoading: isDeleting,
                    disabled: isSigningOut,
                    onTap: onDeleteAccount,
                    color: const Color(0xFFBDBDBD),
                    borderColor: const Color(0xFFEEEEEE),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Profile card ─────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.grade});

  final User user;
  final EcoGrade grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: grade.color.withValues(alpha: 0.15),
            child: Text(
              grade.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? '이름 없음',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email ?? '',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.verify, color: AppColors.primary1, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Google',
                  style: TextStyle(
                    color: AppColors.primary1,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Eco grade card ───────────────────────────

class _EcoGradeCard extends StatelessWidget {
  const _EcoGradeCard({
    required this.grade,
    required this.total,
    required this.co2,
  });

  final EcoGrade grade;
  final int total;
  final double co2;

  @override
  Widget build(BuildContext context) {
    final isMax = grade.maxScans == -1;
    final progress = isMax
        ? 1.0
        : (total - grade.minScans) / (grade.maxScans + 1 - grade.minScans);
    final remaining = isMax ? 0 : grade.maxScans + 1 - total;

    final gradientStart = Color.lerp(grade.color, Colors.white, 0.25)!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, grade.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: grade.color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(grade.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '에코 등급',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    grade.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'CO₂ 절감',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 $total회 스캔',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                isMax ? '최고 등급 달성! 🎉' : '다음 등급까지 $remaining회',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.total, required this.recyclable});

  final int total;
  final int recyclable;

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : ((recyclable / total) * 100).round();
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            icon: Iconsax.scan,
            value: '$total',
            label: '총 스캔',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            icon: Icons.recycling_rounded,
            value: '$recyclable',
            label: '재활용 성공',
            iconColor: AppColors.primary1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            icon: Iconsax.chart,
            value: '$rate%',
            label: '재활용률',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = const Color(0xFF757575),
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}

// ─── Settings button ──────────────────────────

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
    required this.color,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (isLoading || disabled) ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 17),
        label: Text(isLoading ? '처리 중...' : label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
