/// App-wide constants
class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────
  static const String appName = 'سَكرتيرك';
  static const String appSlogan = 'تكلم… والباقي علينا';
  static const String appDescription =
      'مساعدك الشخصي الصوتي لإدارة المهام والمواعيد والمتابعات';

  // ─── Default Settings ─────────────────────────────
  static const int defaultReminderMinutes = 30;
  static const String defaultTimezone = 'Asia/Riyadh';
  static const String defaultLocale = 'ar';
  static const String defaultAfterAsrTime = '15:30';
  static const String defaultAfterMaghribTime = '18:30';
  static const String defaultMorningSummaryTime = '07:00';
  static const String defaultEveningSummaryTime = '21:00';
  static const String defaultWorkdayStart = '08:00';
  static const String defaultWorkdayEnd = '18:00';

  // ─── Free Plan Limits ─────────────────────────────
  static const int freeMonthlyEntries = 30;

  // ─── Snooze Options (minutes) ─────────────────────
  static const int snooze15Min = 15;
  static const int snooze1Hour = 60;
  static const int snoozeTomorrow = -1; // special: next day 9 AM
  static const int snoozeWeek = -7;     // special: next week same time

  // ─── Animation Durations ──────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ─── Edge Function Endpoints ──────────────────────
  static const String parseVoiceInputFn = 'parse-voice-input';
  static const String processActionFn = 'process-action';
  static const String generateBriefingFn = 'generate-briefing';
}
