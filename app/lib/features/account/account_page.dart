import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

enum AccountPageResult { openStats }

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await AuthService.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그아웃 실패: $e')));
      setState(() => _isSigningOut = false);
    }
  }

  Future<void> _signIn() async {
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
    }
  }

  void _openStats() {
    Navigator.pop(context, AccountPageResult.openStats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF333333),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 계정',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: AuthService.userStream,
        initialData: AuthService.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (user == null)
                _SignedOutCard(onSignIn: _signIn)
              else ...[
                _AccountCard(user: user, onOpenStats: _openStats),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSigningOut ? null : _signOut,
                    icon: _isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.logout, size: 18),
                    label: Text(_isSigningOut ? '로그아웃 중...' : '로그아웃'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.onOpenStats});

  final User user;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName ?? '이름 없음';
    final email = user.email ?? '이메일 없음';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _ProfileImage(user: user, radius: 44),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary1.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.verify, color: AppColors.primary1, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Google 계정으로 로그인됨',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenStats,
              icon: const Icon(Iconsax.chart, size: 18),
              label: const Text('통계 페이지로 이동'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard({required this.onSignIn});

  final Future<void> Function() onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[100],
            child: Icon(Iconsax.user, color: Colors.grey[400], size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            '로그인된 계정이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Iconsax.login, size: 18),
              label: const Text('Google로 로그인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.user, required this.radius});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoURL = user.photoURL;

    if (photoURL == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary1.withValues(alpha: 0.12),
        child: Icon(Iconsax.user, color: AppColors.primary1, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(photoURL),
      backgroundColor: Colors.grey[200],
    );
  }
}
