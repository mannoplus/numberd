import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../features/predictions/providers/predictions_provider.dart';
import '../../shared/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final currentLanguage = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final selectedGame = ref.watch(selectedGameProvider);
    final theme = Theme.of(context);

    final cardBg = theme.cardColor;
    final borderColor = theme.dividerColor;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.textTheme.bodyLarge?.color, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s.settings,
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 22),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Language Section
            SectionHeader(
              title: s.languageSection,
              subtitle: 'App Display Language / 顯示語言',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildRadioListTile<AppLanguage>(
                    context: context,
                    title: s.english,
                    subtitle: 'English (United States)',
                    value: AppLanguage.english,
                    groupValue: currentLanguage,
                    onChanged: (val) {
                      if (val != null) ref.read(localeProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildRadioListTile<AppLanguage>(
                    context: context,
                    title: s.chineseTaiwan,
                    subtitle: 'Traditional Chinese (Taiwan)',
                    value: AppLanguage.chineseTaiwan,
                    groupValue: currentLanguage,
                    onChanged: (val) {
                      if (val != null) ref.read(localeProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 2. Theme Mode Section
            SectionHeader(
              title: s.themeModeSection,
              subtitle: 'Visual Color Theme / 視覺顏色主題',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildRadioListTile<ThemeMode>(
                    context: context,
                    title: s.themeDark,
                    subtitle: 'True Black AMOLED Dark Mode',
                    icon: Icons.dark_mode,
                    value: ThemeMode.dark,
                    groupValue: currentThemeMode,
                    onChanged: (val) {
                      if (val != null) ref.read(themeModeProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildRadioListTile<ThemeMode>(
                    context: context,
                    title: s.themeLight,
                    subtitle: 'Clean Crisp Light Mode',
                    icon: Icons.light_mode,
                    value: ThemeMode.light,
                    groupValue: currentThemeMode,
                    onChanged: (val) {
                      if (val != null) ref.read(themeModeProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildRadioListTile<ThemeMode>(
                    context: context,
                    title: s.themeSystem,
                    subtitle: 'Follow OS System Setting',
                    icon: Icons.settings_system_daydream,
                    value: ThemeMode.system,
                    groupValue: currentThemeMode,
                    onChanged: (val) {
                      if (val != null) ref.read(themeModeProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 3. Default Game Preference Section
            SectionHeader(
              title: s.defaultGameSection,
              subtitle: 'Primary Lottery Focus',
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildRadioListTile<String>(
                    context: context,
                    title: s.superLotto,
                    value: 'super_lotto_638',
                    groupValue: selectedGame,
                    onChanged: (val) {
                      if (val != null) ref.read(selectedGameProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildRadioListTile<String>(
                    context: context,
                    title: s.lotto649,
                    value: 'lotto_649',
                    groupValue: selectedGame,
                    onChanged: (val) {
                      if (val != null) ref.read(selectedGameProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildRadioListTile<String>(
                    context: context,
                    title: s.dailyCash539,
                    value: 'daily_cash_539',
                    groupValue: selectedGame,
                    onChanged: (val) {
                      if (val != null) ref.read(selectedGameProvider.notifier).state = val;
                    },
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. System & API Info
            SectionHeader(
              title: s.systemInformation,
              subtitle: 'App & API Diagnostics',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildInfoRow(context, s.appVersion, 'v1.0.0 (Build 1)'),
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, s.apiConnectivity, s.apiConnected, isStatus: true),
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, 'Gemini AI Engine', 'Gemini 2.5 Flash', isStatus: true),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioListTile<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required Color primaryColor,
    required Color borderColor,
  }) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? primaryColor : theme.textTheme.bodyLarge?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(178),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : borderColor,
                  width: isSelected ? 6 : 1.5,
                ),
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isStatus = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            if (isStatus) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                color: isStatus ? Colors.green : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto Mono',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
