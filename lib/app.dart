import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class AarambhaApp extends ConsumerStatefulWidget {
  const AarambhaApp({super.key});

  @override
  ConsumerState<AarambhaApp> createState() => _AarambhaAppState();
}

class _AarambhaAppState extends ConsumerState<AarambhaApp> {
  late final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  late final GoRouter _router =
      AppRouter(_rootNavigatorKey, ref).router;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumora Nine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
