import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/app_navigation_bar.dart';
import 'features/home/home_page.dart';
import 'features/scan/scan_page.dart';
import 'features/stats/stats_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  int _tab = 0;

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenStats: () => setState(() => _tab = 1)),
      const StatsPage(),
    ];

    return Scaffold(
      body: pages[_tab],
      floatingActionButton: AppCameraFloatingButton(onPressed: _openCamera),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavigationBar(
        selectedTab: _tab == 0 ? AppNavTab.home : AppNavTab.stats,
        onHomeTap: () => setState(() => _tab = 0),
        onStatsTap: () => setState(() => _tab = 1),
      ),
    );
  }
}
