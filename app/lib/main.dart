import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/chat_page.dart';
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
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
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

  static const _pages = [ScanPage(), ChatPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: '카메라'),
          NavigationDestination(icon: Icon(Icons.chat), label: '텍스트'),
        ],
      ),
    );
  }
}
