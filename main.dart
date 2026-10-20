import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'screens/duas_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/insights_screen.dart';
import 'screens/tasbih_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Local storage (Hive + preferences)
  final storage = await StorageService.init();

  // 2) Notifications
  final notifications = NotificationService.instance;
  await notifications.init();

  // 3) State / logic (dependency injection through Provider)
  final controller = AppController(storage, notifications);
  await controller.init();

  // 4) Background alarm: re-schedules the next few days every ~12 hours,
  //    even when the app is closed, and again after a phone reboot.
  await AndroidAlarmManager.initialize();
  await AndroidAlarmManager.periodic(
    const Duration(hours: 12),
    7001,
    alarmRefreshCallback,
    wakeup: true,
    rescheduleOnReboot: true,
  );

  runApp(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const IstiqamahApp(),
    ),
  );
}

ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF22C58B),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0B0F14),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0F14),
      elevation: 0,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF121821),
    ),
  );
}

class IstiqamahApp extends StatelessWidget {
  const IstiqamahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Istiqamah',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = context.read<AppController>();
    _controller.requestedTab.addListener(_onTabRequested);
    // Ask for notification + exact alarm permission after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.requestPermissions();
    });
  }

  @override
  void dispose() {
    _controller.requestedTab.removeListener(_onTabRequested);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabRequested() {
    final t = _controller.requestedTab.value;
    if (t >= 0 && mounted) {
      setState(() => _index = t);
      _controller.requestedTab.value = -1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeDashboard(),
          TasbihScreen(),
          DuasScreen(),
          InsightsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'হোম'),
          NavigationDestination(
              icon: Icon(Icons.touch_app_outlined), label: 'তাসবিহ'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'দুআ'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), label: 'হিসাব'),
        ],
      ),
    );
  }
}
