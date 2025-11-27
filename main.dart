import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ble_provider.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/devices_screen.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BLEProvider(),
      child: const FlutterEMGApp(),
    ),
  );
}

class FlutterEMGApp extends StatelessWidget {
  const FlutterEMGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Guide Meter',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        primaryColor: const Color(0xFF0066FF),
        cardColor: const Color(0xFF1A1F3A),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final List<Widget> _pages = const [
    HomeScreen(),
    WorkoutsScreen(),
    DevicesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1F3A),
        selectedItemColor: const Color(0xFF00FF88),
        unselectedItemColor: Colors.white54,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workouts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: "Devices",
          ),
        ],
      ),
    );
  }
}
