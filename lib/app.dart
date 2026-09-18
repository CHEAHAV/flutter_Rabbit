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
          AppColors.setBlend(app.isDarkMode ? 1.0 : 0.0);
          return MaterialApp(
            title: 'Rabbit — QCM Master',
            debugShowCheckedModeBanner: false,
            theme: app.isDarkMode ? AppTheme.dark() : AppTheme.light(),
            themeAnimationDuration: const Duration(milliseconds: 280),
            themeAnimationCurve: Curves.easeInOutCubic,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
