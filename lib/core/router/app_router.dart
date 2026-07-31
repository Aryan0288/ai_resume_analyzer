import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/templates/presentation/templates_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/resume/presentation/ingestion_screen.dart';
import '../../features/resume/presentation/workspace_shell.dart';
import '../../features/resume/presentation/critique_screen.dart';
import '../../features/interview/presentation/interview_prep_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Centralized routing configuration using go_router.
/// Supports state synchronization and Web routing parameters.
class AppRouter {
  static GoRouter getRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // ShellRoute keeps the persistent top header & workspace shell across all sections
        ShellRoute(
          builder: (context, state, child) => WorkspaceShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: IngestionScreen(),
              ),
            ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
            GoRoute(
              path: '/templates',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TemplatesScreen(),
              ),
            ),
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HistoryScreen(),
              ),
            ),
            GoRoute(
              path: '/workspace/critique',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CritiqueScreen(),
              ),
            ),
            GoRoute(
              path: '/workspace/prep',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: InterviewPrepScreen(),
              ),
            ),
            GoRoute(
              path: '/workspace/quiz',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: QuizScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
