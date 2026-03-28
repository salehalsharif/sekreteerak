import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/followups/followups_screen.dart';
import '../screens/inbox/inbox_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main app with bottom nav shell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TasksListScreen(),
            ),
          ),
          GoRoute(
            path: '/followups',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FollowupsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Detail screens (outside shell)
      GoRoute(
        path: '/task/:id',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
    ],
  );
});
