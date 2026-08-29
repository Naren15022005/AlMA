import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/router/route_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/gradient_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final initialRoute = await loadLastRoute();
  final container = ProviderContainer(overrides: [
    initialRouteProvider.overrideWithValue(initialRoute),
  ]);
  await container.read(gradientThemeProvider.notifier).load();
  runApp(UncontrolledProviderScope(
    container: container,
    child: const AlmaApp(),
  ));
}

class AlmaApp extends ConsumerWidget {
  const AlmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ALMA',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
