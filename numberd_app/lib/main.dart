import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/theme/colors.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/predictions/predictions_screen.dart';
import 'features/statistics/statistics_screen.dart';
import 'features/history/history_screen.dart';
import 'features/combinations/combinations_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/nav_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NumberDApp()));
}

class NumberDApp extends ConsumerWidget {
  const NumberDApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'NumberD',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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
    final s = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              size: 22,
            ),
            tooltip: s.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.border : AppColors.lightBorder,
              width: 1,
            ),
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
          backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
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
              label: s.navDashboard,
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 1, isSelected: _currentIndex == 1),
              ),
              label: s.navPredict,
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 2, isSelected: _currentIndex == 2),
              ),
              label: s.navStats,
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 3, isSelected: _currentIndex == 3),
              ),
              label: s.navHistory,
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: NavIcon(index: 4, isSelected: _currentIndex == 4),
              ),
              label: s.navPicker,
            ),
          ],
        ),
      ),
    );
  }
}

