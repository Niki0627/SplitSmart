// lib/core/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../features/auth/auth_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/groups/create_group_screen.dart';
import '../features/groups/group_details_screen.dart';
import '../features/groups/edit_group_screen.dart';
import '../features/groups/add_member_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/expenses/calculate_tally_screen.dart';
import '../features/expenses/settle_up_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/history/history_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../shared/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;
      final user = authState.value;
      final isAuth = state.matchedLocation == '/auth';
      final isSplash = state.matchedLocation == '/';
      if (user == null && !isAuth && !isSplash) return '/auth';
      if (user != null && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
          GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
          GoRoute(path: '/reminders', builder: (c, s) => const RemindersScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/groups/create', builder: (c, s) => const CreateGroupScreen()),
      GoRoute(
        path: '/groups/:id',
        builder: (c, s) => GroupDetailsScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/expense',
        builder: (c, s) => AddExpenseScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/tally',
        builder: (c, s) => CalculateTallyScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/settle',
        builder: (c, s) => SettleUpScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/:id/edit',
        builder: (c, s) => EditGroupScreen(
          groupId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/groups/:id/add-member',
        builder: (c, s) => AddMemberScreen(
          groupId: s.pathParameters['id']!,
        ),
      ),
    ],
  );
});
