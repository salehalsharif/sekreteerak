import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/providers.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Profile Section ────────────────────────
          _sectionTitle('الملف الشخصي'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.person_rounded,
                title: 'الاسم',
                subtitle: 'المستخدم',
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.email_rounded,
                title: 'البريد الإلكتروني',
                subtitle: 'user@example.com',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Reminders Section ──────────────────────
          _sectionTitle('التذكيرات'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.notifications_rounded,
                title: 'التذكير الافتراضي',
                subtitle: settings.when(
                  data: (s) =>
                      'قبل ${s?.defaultReminderMinutes ?? 30} دقيقة من الموعد',
                  loading: () => '...',
                  error: (_, __) => 'قبل 30 دقيقة',
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.wb_sunny_rounded,
                title: 'الملخص الصباحي',
                subtitle: settings.when(
                  data: (s) => s?.morningSummaryTime ?? '07:00',
                  loading: () => '...',
                  error: (_, __) => '07:00',
                ),
                trailing: Switch(
                  value: settings.when(
                    data: (s) => s?.summaryEnabled ?? true,
                    loading: () => true,
                    error: (_, __) => true,
                  ),
                  onChanged: (val) {},
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.nights_stay_rounded,
                title: 'الملخص المسائي',
                subtitle: settings.when(
                  data: (s) => s?.eveningSummaryTime ?? '21:00',
                  loading: () => '...',
                  error: (_, __) => '21:00',
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Time Windows Section ───────────────────
          _sectionTitle('نوافذ الوقت'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.wb_twilight_rounded,
                title: 'بعد العصر',
                subtitle: settings.when(
                  data: (s) => s?.afterAsrTime ?? '15:30',
                  loading: () => '...',
                  error: (_, __) => '15:30',
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'بعد المغرب',
                subtitle: settings.when(
                  data: (s) => s?.afterMaghribTime ?? '18:30',
                  loading: () => '...',
                  error: (_, __) => '18:30',
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.schedule_rounded,
                title: 'بداية يوم العمل',
                subtitle: settings.when(
                  data: (s) => s?.workdayStart ?? '08:00',
                  loading: () => '...',
                  error: (_, __) => '08:00',
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.schedule_rounded,
                title: 'نهاية يوم العمل',
                subtitle: settings.when(
                  data: (s) => s?.workdayEnd ?? '18:00',
                  loading: () => '...',
                  error: (_, __) => '18:00',
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Integrations ───────────────────────────
          _sectionTitle('التكاملات'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.calendar_month_rounded,
                title: 'Google Calendar',
                subtitle: 'غير متصل',
                trailing: const Icon(
                  Icons.link_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Subscription ───────────────────────────
          _sectionTitle('الاشتراك'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'ترقية إلى Pro',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إدخالات غير محدودة • ملخصات ذكية • تقويم',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('اشترك الآن'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── About ──────────────────────────────────
          _sectionTitle('حول'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.info_rounded,
                title: 'إصدار التطبيق',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.privacy_tip_rounded,
                title: 'سياسة الخصوصية',
                onTap: () {},
              ),
              const Divider(height: 1),
              _settingsTile(
                icon: Icons.description_rounded,
                title: 'الشروط والأحكام',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            )
          : null,
      trailing: trailing ??
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppTheme.textMuted,
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
