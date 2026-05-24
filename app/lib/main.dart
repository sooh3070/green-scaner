import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'core/theme/app_colors.dart';
import 'features/chat/chat_page.dart';
import 'features/home/home_page.dart';
import 'features/scan/scan_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'assets/.env');
  runApp(const ProviderScope(child: GreenScannerApp()));
}

class GreenScannerApp extends StatelessWidget {
  const GreenScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '분리배출 판별',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary1,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const _RootNav(),
    );
  }
}

class _RootNav extends StatefulWidget {
  const _RootNav();

  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;

  static const _pages = [HomePage(), ChatPage()];

  void _openCamera(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: FloatingActionButton(
          onPressed: () => _openCamera(context),
          backgroundColor: AppColors.primary1,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(Iconsax.camera5, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Iconsax.home_2,
                label: '홈',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              const SizedBox(width: 64),
              _NavItem(
                icon: Iconsax.message,
                label: '채팅',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : const Color(0xFFBBBBBB);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
