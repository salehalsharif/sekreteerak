import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';

/// Calendar screen — simplified weekly/daily view
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'التقويم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Week strip
          _buildWeekStrip(),

          const SizedBox(height: 16),

          // Day tasks
          Expanded(
            child: Center(
              child: EmptyState(
                icon: Icons.calendar_month_rounded,
                title: 'التقويم قريبًا',
                subtitle: 'سيتم ربط التقويم مع Google Calendar',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    const dayNames = ['إث', 'ث', 'أر', 'خ', 'ج', 'س', 'أح'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final isToday = day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;

          return Column(
            children: [
              Text(
                dayNames[i],
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: isToday ? AppTheme.primaryColor : AppTheme.textMuted,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primaryColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
