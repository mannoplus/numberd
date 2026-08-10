import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  english,
  chineseTaiwan,
}

final localeProvider = StateProvider<AppLanguage>((ref) => AppLanguage.english);

class AppStrings {
  final AppLanguage lang;

  AppStrings(this.lang);

  bool get isZh => lang == AppLanguage.chineseTaiwan;

  // App & Shell
  String get appTitle => 'NumberD';
  String get settings => isZh ? '設定' : 'Settings';
  String get live => 'LIVE';

  // Navigation Tabs
  String get navDashboard => isZh ? '儀表板' : 'DASHBOARD';
  String get navPredict => isZh ? 'AI 預測' : 'PREDICT';
  String get navStats => isZh ? '統計分析' : 'STATS';
  String get navHistory => isZh ? '歷史開獎' : 'HISTORY';
  String get navPicker => isZh ? '組合選號' : 'PICKER';

  // Games
  String get superLotto => isZh ? '威力彩 6/38' : 'Super Lotto 638';
  String get lotto649 => isZh ? '大樂透 6/49' : 'Lotto 6/49';
  String get dailyCash539 => isZh ? '今彩539' : 'Daily Cash 539';

  // Dashboard
  String get latestDraw => isZh ? '最新開獎' : 'LATEST DRAW';
  String get nextDrawCountdown => isZh ? '距離下次開獎' : 'NEXT DRAW IN';
  String get jackpotPrize => isZh ? '頭獎預估金額' : 'EST. JACKPOT';
  String get officialBroadcast => isZh ? '官方直播' : 'Official Broadcast';
  String get liveStreamSubtitle => isZh ? 'iNews 現場即時直播' : 'iNews Live Stream';

  // Predict
  String get intelligence => isZh ? '智慧分析' : 'Intelligence';
  String get forecastEngine => isZh ? '演算法預測引擎' : 'Algorithmic Forecast Engine';
  String get targetSum => isZh ? '目標總和' : 'Target Sum';
  String get hotColdRatio => isZh ? '冷熱比例' : 'Hot/Cold';
  String get repeatProbability => isZh ? '連莊機率' : 'Repeat';
  String get alphaSet => isZh ? 'Alpha 均衡組' : 'Alpha (Balanced)';
  String get betaSet => isZh ? 'Beta 動能組' : 'Beta (Momentum)';
  String get gammaSet => isZh ? 'Gamma 渾沌組' : 'Gamma (Chaos)';
  String get tapForAiDeepDive => isZh ? '點擊檢視 AI 50期深度分析 ↗' : 'TAP FOR AI 50-DRAW DEEP DIVE ↗';

  // Statistics
  String get statistics => isZh ? '統計數據' : 'Statistics';
  String get historicalAnalysis => isZh ? '歷史數據分佈分析' : 'Historical Analysis';
  String get hotNumbers => isZh ? '熱門號碼' : 'Hot Numbers';
  String get coldNumbers => isZh ? '冷門號碼' : 'Cold Numbers';
  String get overdueGap => isZh ? '遺漏最大間隔' : 'Overdue / Max Gap';
  String get frequencyDistribution => isZh ? '號碼出現頻率分佈' : 'Frequency Distribution';

  // History
  String get drawHistory => isZh ? '歷史開獎' : 'Draw History';
  String get recent50Draws => isZh ? '近50期官方確認紀錄' : '50 Most Recent Confirmed Draws';
  String get period => isZh ? '期別' : 'Period';
  String get drawDate => isZh ? '開獎日期' : 'Date';

  // Combinatorial Picker
  String get combinatorialEngine => isZh ? '組合生成' : 'Combinatorial Engine';
  String get smartTicketBuilder => isZh ? '智慧複式包號系統' : 'Smart Ticket Generator';
  String get step1SelectNumbers => isZh ? '步驟 1：選擇 12-16 個核心號碼' : 'Step 1: Select 12-16 Numbers';
  String get step2Confirm => isZh ? '步驟 2：確認號碼池' : 'Step 2: Confirm Selection';
  String get step3Quantity => isZh ? '步驟 3：選擇注數生成' : 'Step 3: Select Ticket Quantity';
  String get generateTickets => isZh ? '生成複式彩券' : 'Generate Combinatorial Tickets';
  String get resetSelection => isZh ? '重設選擇' : 'Reset Selection';

  // Settings Screen
  String get languageSection => isZh ? '語言語言 / Language' : 'Language';
  String get english => 'English';
  String get chineseTaiwan => '繁體中文 (台灣)';
  String get themeModeSection => isZh ? '主題模式 / Theme' : 'Theme Mode';
  String get themeDark => isZh ? '深色模式 (AMOLED)' : 'Dark Mode (AMOLED)';
  String get themeLight => isZh ? '淺色明亮模式' : 'Light Mode';
  String get themeSystem => isZh ? '跟隨系統預設' : 'System Default';
  String get defaultGameSection => isZh ? '預設彩券類別' : 'Default Lottery Game';
  String get systemInformation => isZh ? '系統資訊' : 'System Information';
  String get appVersion => isZh ? '應用程式版本' : 'App Version';
  String get apiConnectivity => isZh ? '台灣彩券 API 連線狀態' : 'Taiwan Lottery API Status';
  String get apiConnected => isZh ? '已連線 (正常)' : 'Connected (Active)';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(localeProvider);
  return AppStrings(lang);
});
