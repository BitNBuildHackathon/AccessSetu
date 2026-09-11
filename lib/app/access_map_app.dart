import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/map/presentation/main_shell.dart';
import 'package:access_map/features/onboarding/presentation/mode_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccessMapApp extends StatelessWidget {
  const AccessMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadPlaces(),
      child: MaterialApp(
        title: 'AccessMap',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Consumer<AppState>(
          builder: (context, state, _) {
            if (!state.profile.onboardingComplete) {
              return const ModeSelectionScreen();
            }
            return const MainShell();
          },
        ),
      ),
    );
  }
}
