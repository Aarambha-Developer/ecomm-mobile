import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class AarambhaApp extends ConsumerWidget {
  const AarambhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final router = AppRouter(rootNavigatorKey).router;

    return MaterialApp.router(
      title: 'Lumora Nine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
