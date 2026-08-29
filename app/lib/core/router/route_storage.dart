import 'package:shared_preferences/shared_preferences.dart';

const _kLastRouteKey = 'last_route';

const _persistedRoutes = {
  '/home',
  '/home/schedule',
  '/home/distance',
  '/home/diary',
  '/home/thoughts',
};

Future<String> loadLastRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kLastRouteKey);
  if (saved != null && _persistedRoutes.contains(saved)) return saved;
  return '/home';
}

Future<void> saveLastRoute(String route) async {
  if (!_persistedRoutes.contains(route)) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastRouteKey, route);
}
