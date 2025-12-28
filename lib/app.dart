import 'package:flutter/material.dart';
import 'core/theme/wear_theme.dart';
import 'navigation/app_router.dart';

/// Main application widget.
class JellyfinWearApp extends StatelessWidget {
  const JellyfinWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jellyfin Wear',
      debugShowCheckedModeBanner: false,
      theme: WearTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
