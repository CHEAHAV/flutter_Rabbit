import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class RabbitApp extends StatelessWidget {
  const RabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: Consumer<AppState>(
        builder: (context, app, _) {
          // Drives a smooth crossfade between the light and dark palettes
          // whenever app.isDarkMode flips, instead of snapping instantly.
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: app.isDarkMode ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            builder: (context, t, _) {
              AppColors.setBlend(t);
              return MaterialApp(
                title: 'Rabbit — QCM Master',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.animated(),
                themeAnimationDuration: Duration.zero,
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
