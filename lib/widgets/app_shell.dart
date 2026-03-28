import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/providers.dart';

/// Main app shell with bottom navigation and floating mic button
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButton: _buildMicFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context, ref, currentIndex),
    );
  }

  Widget _buildMicFAB(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.glowShadow(AppTheme.primaryColor),
      ),
      child: FloatingActionButton(
        onPressed: () => _showVoiceCapture(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        heroTag: 'mic_fab',
        child: const Icon(
          Icons.mic_rounded,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                context, ref,
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                index: 0,
                route: '/home',
                currentIndex: currentIndex,
              ),
              _navItem(
                context, ref,
                icon: Icons.checklist_rounded,
                label: 'المهام',
                index: 1,
                route: '/tasks',
                currentIndex: currentIndex,
              ),
              const SizedBox(width: 64), // Space for FAB
              _navItem(
                context, ref,
                icon: Icons.people_alt_rounded,
                label: 'المتابعات',
                index: 2,
                route: '/followups',
                currentIndex: currentIndex,
              ),
              _navItem(
                context, ref,
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                index: 3,
                route: '/settings',
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required int index,
    required String route,
    required int currentIndex,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        ref.read(bottomNavIndexProvider.notifier).state = index;
        context.go(route);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppTheme.animFast,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceCapture(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _VoiceCaptureSheet(),
    );
  }
}

/// Voice capture bottom sheet (launched from FAB)
class _VoiceCaptureSheet extends ConsumerStatefulWidget {
  const _VoiceCaptureSheet();

  @override
  ConsumerState<_VoiceCaptureSheet> createState() => _VoiceCaptureSheetState();
}

class _VoiceCaptureSheetState extends ConsumerState<_VoiceCaptureSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isRecording = false;
  String _transcribedText = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            _isRecording
                ? 'جارِ الاستماع...'
                : _isProcessing
                    ? 'جارِ التحليل...'
                    : 'ماذا تريد أن أتذكر لك؟',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isRecording
                ? 'اضغط مرة أخرى لإيقاف التسجيل'
                : 'اضغط على الميكروفون وتحدث',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),

          const Spacer(),

          // Transcribed text display
          if (_transcribedText.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                _transcribedText,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const Spacer(),

          // Mic button with pulse animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isRecording
                      ? [
                          BoxShadow(
                            color: AppTheme.errorColor.withOpacity(
                              0.3 + (_pulseController.value * 0.2),
                            ),
                            blurRadius: 24 + (_pulseController.value * 16),
                            spreadRadius: _pulseController.value * 8,
                          ),
                        ]
                      : AppTheme.glowShadow(AppTheme.primaryColor),
                ),
                child: Material(
                  color: _isRecording ? AppTheme.errorColor : AppTheme.primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _toggleRecording,
                    customBorder: const CircleBorder(),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Text input alternative
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextButton.icon(
              onPressed: _showTextInput,
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: const Text('أو اكتب نصًا'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _pulseController.repeat(reverse: true);
        _transcribedText = '';
        // Start actual recording via AudioService + SpeechService
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _isProcessing = true;
        // Stop recording, send to AI parse, show preview
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isProcessing = false);
            Navigator.pop(context);
            // Navigate to parsed preview
          }
        });
      }
    });
  }

  void _showTextInput() {
    showDialog(
      context: context,
      builder: (ctx) => _TextInputDialog(
        onSubmit: (text) {
          Navigator.pop(context);
          // Process text input through AI parse
        },
      ),
    );
  }
}

/// Text input dialog as alternative to voice
class _TextInputDialog extends StatefulWidget {
  final Function(String) onSubmit;

  const _TextInputDialog({required this.onSubmit});

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل المهمة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'مثال: ذكرني أراجع الفواتير بكرة الساعة 11',
                hintStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textMuted,
                ),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textPrimary,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onSubmit(_controller.text.trim());
                  }
                },
                child: const Text('إضافة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
