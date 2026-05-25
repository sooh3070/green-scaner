import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/scan_result.dart';
import 'scan_provider.dart';

const _nonRecyclable = {'일반쓰레기', '특수폐기물'};

bool _isRecyclable(String verdict) => !_nonRecyclable.contains(verdict);

const _orange = Color(0xFFFF8C00);

String _conditionStatusLabel(String condition) {
  if (condition.contains('세척')) return '세척 후 배출';
  if (condition.contains('라벨') || condition.contains('테이프')) return '제거 후 배출';
  if (condition.contains('분리') || condition.contains('부품')) return '분리 후 배출';
  return '조건부 배출';
}

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({
    super.key,
    required this.imageFile,
    this.fromKiosk = false,
    this.countdownSeconds = 30,
  });
  final File imageFile;
  final bool fromKiosk;
  final int countdownSeconds;

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  Timer? _timer;
  int _remaining = 0;
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanProvider.notifier).scanImage(widget.imageFile);
    });
  }

  void _startCountdown() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        ref.read(scanProvider.notifier).reset();
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retake() {
    ref.read(scanProvider.notifier).reset();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    if (widget.fromKiosk && !scanState.isLoading && scanState.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: widget.fromKiosk
          ? _KioskCountdownBar(remaining: _remaining, total: widget.countdownSeconds)
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.popUntil(context, (route) => route.isFirst),
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text('홈으로'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: AppColors.primary1,
                          side: const BorderSide(color: AppColors.primary1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _retake,
                        icon: const Icon(Icons.camera_alt_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('다시 촬영'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary1,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Color(0xFF333333)),
                    onPressed: _retake,
                  ),
                  const Text(
                    'AI 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            // 스크롤 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    // 촬영 이미지 카드
                    _ImageCard(imageFile: widget.imageFile),
                    const SizedBox(height: 14),

                    // 결과 영역
                    scanState.isLoading
                        ? const _LoadingView()
                        : scanState.hasError
                            ? _ErrorView(error: '${scanState.error}')
                            : scanState.value != null
                                ? _ResultContent(result: scanState.value!)
                                : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 이미지 카드
// ─────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.imageFile});
  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.file(imageFile, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 로딩
// ─────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary1, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'AI가 분석 중이에요...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 에러
// ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 44, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            '분석에 실패했어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 결과 콘텐츠
// ─────────────────────────────────────────────
class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final recyclable = _isRecyclable(result.verdict);
    final hasCondition = result.condition != null;

    final Color accent;
    final String statusLabel;
    if (!recyclable) {
      accent = const Color(0xFFE53935);
      statusLabel = '배출 불가능';
    } else if (hasCondition) {
      accent = _orange;
      statusLabel = _conditionStatusLabel(result.condition!);
    } else {
      accent = AppColors.primary1;
      statusLabel = '배출 가능';
    }

    return Column(
      children: [
        _HeaderCard(result: result, statusLabel: statusLabel, accent: accent),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.recycling_rounded,
          iconColor: accent,
          label: '처리 방법',
          content: result.action,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF999999),
          label: '판단 근거',
          content: result.reason,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 헤더 카드
// ─────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.result,
    required this.statusLabel,
    required this.accent,
  });
  final ScanResult result;
  final String statusLabel;
  final Color accent;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뱃지 + 배출 가능 여부
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AI 분석',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 판정 결과 + 오염도 게이지
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  result.verdict,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              _PollutionGauge(pollution: result.pollution),
            ],
          ),

          // 처리 조건 칩
          if (result.condition != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.condition!,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 오염도 원형 게이지
// ─────────────────────────────────────────────
class _PollutionGauge extends StatelessWidget {
  const _PollutionGauge({required this.pollution});
  final int pollution;

  Color get _gaugeColor {
    if (pollution <= 30) return const Color(0xFF1DC862);
    if (pollution <= 60) return const Color(0xFFFF8C00);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: pollution / 100,
            strokeWidth: 6,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pollution%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '오염도',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
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

// ─────────────────────────────────────────────
// 정보 카드
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.content,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 키오스크 카운트다운 바
// ─────────────────────────────────────────────
class _KioskCountdownBar extends StatelessWidget {
  const _KioskCountdownBar({required this.remaining, required this.total});
  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = remaining / total;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_rounded, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  '$remaining초 후 키오스크 화면으로 돌아갑니다',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFEEEEEE),
                color: AppColors.primary1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
