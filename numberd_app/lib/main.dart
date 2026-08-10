import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/predictions/predictions_screen.dart';
import 'features/statistics/statistics_screen.dart';
import 'features/history/history_screen.dart';
import 'features/combinations/combinations_screen.dart';
import 'shared/widgets/nav_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NumberDApp()));
}

class NumberDApp extends StatelessWidget {
  const NumberDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NumberD',
      theme: AppTheme.darkTheme,
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const PredictionsScreen(),
    const StatisticsScreen(),
    const HistoryScreen(),
    const CombinationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 0, isSelected: _currentIndex == 0),
              ),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 1, isSelected: _currentIndex == 1),
              ),
              label: 'PREDICT',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 2, isSelected: _currentIndex == 2),
              ),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 3, isSelected: _currentIndex == 3),
              ),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 4, isSelected: _currentIndex == 4),
              ),
              label: 'PICKER',
            ),
          ],
        ),
      ),
    );
  }
}

