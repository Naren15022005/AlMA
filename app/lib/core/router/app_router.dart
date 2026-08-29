import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/pair_code_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../widgets/main_shell.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/distance/presentation/pages/distance_page.dart';
import '../../features/diary/presentation/pages/diary_page.dart';
import '../../features/thoughts/presentation/pages/thoughts_page.dart';
import 'route_storage.dart';

final initialRouteProvider = Provider<String>((_) => '/home');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final initialRoute = ref.watch(initialRouteProvider);

  return GoRouter(
    initialLocation: initialRoute,
    observers: [_RouteObserver()],
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final path = state.uri.path;

      if (!isAuth) {
        if (path == '/register') return null;
        return '/login';
      }

      if (isAuth && (path == '/login' || path == '/register' || path == '/pair-code')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/pair-code', builder: (_, __) => const PairCodePage()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const MainShell(),
        routes: [
          GoRoute(path: 'schedule', builder: (_, __) => const SchedulePage()),
          GoRoute(path: 'distance', builder: (_, __) => const DistancePage()),
          GoRoute(path: 'diary', builder: (_, __) => const DiaryPage()),
          GoRoute(path: 'thoughts', builder: (_, __) => const ThoughtsPage()),
        ],
      ),
    ],
  );
});

class _RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) => _save(route);

  @override
  void didPop(Route route, Route? previousRoute) => _save(previousRoute);

  void _save(Route? route) {
    final name = route?.settings.name;
    if (name != null) saveLastRoute(name);
  }
}
