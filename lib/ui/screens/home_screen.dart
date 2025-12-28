import 'package:flutter/material.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Main home screen with menu options.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Browse Libraries
          _HomeMenuItem(
            icon: Icons.folder_outlined,
            label: 'Browse',
            onTap: () => Navigator.pushNamed(context, AppRoutes.libraryPicker),
            padding: padding,
          ),
          // Remote Control
          _HomeMenuItem(
            icon: Icons.gamepad_outlined,
            label: 'Remote',
            onTap: () => Navigator.pushNamed(context, AppRoutes.sessionPicker),
            padding: padding,
          ),
          // Settings
          _HomeMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            padding: padding,
          ),
        ],
      ),
    );
  }
}

class _HomeMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const _HomeMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: WearTheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: WearTheme.jellyfinPurple,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
