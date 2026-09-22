import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class RabbitApp extends StatefulWidget {
  const RabbitApp({super.key});

  @override
  State<RabbitApp> createState() => _RabbitAppState();
}

class _RabbitAppState extends State<RabbitApp> with WidgetsBindingObserver {
  late final AppState _app = AppState()..bootstrap();

  /// Needed so an expiring session can also drop whatever was pushed on top of
  /// the root (a quiz, a review page): swapping the root widget alone would
  /// leave those routes covering the login screen.
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-checks the one-day login session every time the app comes back to the
  /// foreground, so a session that ran out while the app sat in the background
  /// is closed on return instead of surviving until the next cold start.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final wasSignedIn = _app.isSignedIn;
    _app.revalidateSession().then((_) {
      if (!mounted || !wasSignedIn || _app.isSignedIn) return;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _app,
      child: Consumer<AppState>(
        builder: (context, app, _) {
          AppColors.setBlend(app.isDarkMode ? 1.0 : 0.0);
          return MaterialApp(
            title: 'Rabbit',
            debugShowCheckedModeBanner: false,
            navigatorKey: _navigatorKey,
            theme: app.isDarkMode ? AppTheme.dark() : AppTheme.light(),
            themeAnimationDuration: const Duration(milliseconds: 280),
            themeAnimationCurve: Curves.easeInOutCubic,
            home: const AppGate(),
          );
        },
      ),
    );
  }
}

/// Decides what the app's first route shows: the splash while the bank loads,
/// the login screen while there is no valid session, and the app itself once
/// there is one.
///
/// This is declarative on purpose. Signing in, signing out and a session
/// running out are then all the same thing - a change of [AppState.isSignedIn]
/// - instead of three different places having to remember to navigate.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // Not `const`: these screens read the mutable AppColors palette, and a
    // const instance would keep the colours it was first built with.
    final Widget child;
    if (app.booting || app.bootError != null) {
      child = SplashScreen();
    } else if (!app.isSignedIn) {
      child = LoginScreen();
    } else {
      child = HomeShell();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}
