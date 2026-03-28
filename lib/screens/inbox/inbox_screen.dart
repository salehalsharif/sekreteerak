import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/inbox_entry_model.dart';
import '../../providers/providers.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/common_widgets.dart';

/// Inbox screen — raw voice/text entries before & after processing
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'الوارد الصوتي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: inbox.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_rounded,
              title: 'الوارد فارغ',
              subtitle: 'الإدخالات الصوتية والنصية ستظهر هنا',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return _InboxCard(entry: entries[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'خطأ في التحميل',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  final InboxEntry entry;

  const _InboxCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: entry.isParsed
              ? AppTheme.successColor.withOpacity(0.2)
              : entry.isFailed
                  ? AppTheme.errorColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                entry.source == SourceType.voice
                    ? Icons.mic_rounded
                    : Icons.edit_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                entry.source == SourceType.voice ? 'صوتي' : 'نصي',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              _statusBadge(),
              const SizedBox(width: 8),
              Text(
                DateHelpers.getRelativeDate(entry.createdAt),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Raw text
          if (entry.rawText != null)
            Text(
              entry.rawText!,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),

          // Parsed result preview
          if (entry.isParsed && entry.parsedJson != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.parsedJson!['title'] as String? ?? 'تم التحليل',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge() {
    Color color;
    String label;

    switch (entry.status) {
      case ParseStatus.pending:
        color = AppTheme.warningColor;
        label = 'قيد المعالجة';
        break;
      case ParseStatus.parsed:
        color = AppTheme.successColor;
        label = 'تم';
        break;
      case ParseStatus.failed:
        color = AppTheme.errorColor;
        label = 'فشل';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
