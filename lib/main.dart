import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/jellyfin/jellyfin_client_wrapper.dart';
import 'data/jellyfin/server_discovery.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/library_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'state/app_state.dart';
import 'state/library_state.dart';
import 'state/remote_state.dart';
import 'state/session_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for Wear OS
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for AMOLED
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );

  // Create core dependencies
  final jellyfinClient = JellyfinClientWrapper();
  final serverDiscovery = ServerDiscovery();
  final authRepository = AuthRepository(jellyfinClient);
  final libraryRepository = LibraryRepository(jellyfinClient);
  final sessionRepository = SessionRepository(jellyfinClient);
  final settingsRepository = SettingsRepository();

  runApp(
    MultiProvider(
      providers: [
        // Core client wrapper (not a ChangeNotifier, just a value)
        Provider<JellyfinClientWrapper>.value(value: jellyfinClient),

        // Repositories (not ChangeNotifiers)
        Provider<AuthRepository>.value(value: authRepository),
        Provider<LibraryRepository>.value(value: libraryRepository),
        Provider<SessionRepository>.value(value: sessionRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),

        // App state
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(
            client: jellyfinClient,
            authRepository: authRepository,
            serverDiscovery: serverDiscovery,
          ),
        ),

        // Library state
        ChangeNotifierProvider<LibraryState>(
          create: (_) => LibraryState(libraryRepository),
        ),

        // Session state
        ChangeNotifierProvider<SessionState>(
          create: (_) => SessionState(sessionRepository),
        ),

        // Remote state
        ChangeNotifierProvider<RemoteState>(
          create: (_) => RemoteState(jellyfinClient),
        ),
      ],
      child: const JellyfinWearApp(),
    ),
  );
}
