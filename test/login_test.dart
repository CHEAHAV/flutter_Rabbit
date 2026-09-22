// Covers the private-app gate: only snoopy/1qaz!QAZ gets in, a successful
// login is remembered for exactly one day, and the app returns to the login
// screen once that day is over (or when the user signs out).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabbit/app.dart';
import 'package:rabbit/screens/home_shell.dart';
import 'package:rabbit/screens/login_screen.dart';
import 'package:rabbit/services/auth_service.dart';
import 'package:rabbit/state/app_state.dart';
import 'package:rabbit/theme/app_theme.dart';

const _user = 'snoopy';
const _pass = '1qaz!QAZ';
const _kSignedInAt = 'rabbit.auth.signedInAt';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A boot with the given stored preferences, from a clean auth singleton.
  Future<AppState> boot(
    WidgetTester tester, [
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    AuthService.instance.resetForTesting();
    final app = AppState();
    await tester.runAsync(app.bootstrap);
    return app;
  }

  /// Wires the gate exactly as app.dart does, so the tests exercise the real
  /// "which screen am I on" decision rather than a stand-in.
  Future<void> pumpGate(WidgetTester tester, AppState app) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(theme: AppTheme.light(), home: const AppGate()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeCredentials(
    WidgetTester tester,
    String user,
    String pass,
  ) async {
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), user);
    await tester.enterText(fields.at(1), pass);
    await tester.tap(find.text('ចូលប្រើ'));
    await tester.pumpAndSettle();
  }

  // ---- The gate ---------------------------------------------------------

  testWidgets('a first launch lands on the login screen, not the app', (
    tester,
  ) async {
    final app = await boot(tester);
    await pumpGate(tester, app);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('the wrong password does not open the app', (tester) async {
    final app = await boot(tester);
    await pumpGate(tester, app);

    await typeCredentials(tester, _user, 'wrong-password');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
    expect(find.text('ឈ្មោះអ្នកប្រើ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ'), findsOneWidget);
    expect(app.isSignedIn, isFalse);
  });

  testWidgets('the wrong username does not open the app', (tester) async {
    final app = await boot(tester);
    await pumpGate(tester, app);

    await typeCredentials(tester, 'woodstock', _pass);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(app.isSignedIn, isFalse);
  });

  testWidgets('empty fields are refused without touching the session', (
    tester,
  ) async {
    final app = await boot(tester);
    await pumpGate(tester, app);

    await tester.tap(find.text('ចូលប្រើ'));
    await tester.pumpAndSettle();

    expect(find.text('សូមបញ្ចូលឈ្មោះអ្នកប្រើ និងពាក្យសម្ងាត់'), findsOneWidget);
    expect(app.isSignedIn, isFalse);
  });

  testWidgets('the right credentials open the app', (tester) async {
    final app = await boot(tester);
    await pumpGate(tester, app);

    await typeCredentials(tester, _user, _pass);

    expect(app.isSignedIn, isTrue);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  // ---- The one-day session ---------------------------------------------

  testWidgets('a session opened minutes ago skips the login screen', (
    tester,
  ) async {
    final minutesAgo = DateTime.now().subtract(const Duration(minutes: 30));
    final app = await boot(tester, {
      _kSignedInAt: minutesAgo.millisecondsSinceEpoch,
    });
    await pumpGate(tester, app);

    expect(app.isSignedIn, isTrue);
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('a session opened 23 hours ago still skips the login screen', (
    tester,
  ) async {
    final justInside = DateTime.now().subtract(const Duration(hours: 23));
    final app = await boot(tester, {
      _kSignedInAt: justInside.millisecondsSinceEpoch,
    });
    await pumpGate(tester, app);

    expect(app.isSignedIn, isTrue);
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('a session older than a day asks for the credentials again', (
    tester,
  ) async {
    final expired = DateTime.now().subtract(const Duration(hours: 25));
    final app = await boot(tester, {
      _kSignedInAt: expired.millisecondsSinceEpoch,
    });
    await pumpGate(tester, app);

    expect(app.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);

    // ... and the expired stamp is cleared, not left to be re-checked.
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getInt(_kSignedInAt), isNull);
  });

  testWidgets('a stamp in the future (clock moved) is not trusted', (
    tester,
  ) async {
    final future = DateTime.now().add(const Duration(hours: 2));
    final app = await boot(tester, {
      _kSignedInAt: future.millisecondsSinceEpoch,
    });
    await pumpGate(tester, app);

    expect(app.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signing in stores a session that a later launch reuses', (
    tester,
  ) async {
    final app = await boot(tester);
    await pumpGate(tester, app);
    await typeCredentials(tester, _user, _pass);
    expect(app.isSignedIn, isTrue);

    // Relaunch: a brand-new AppState over the same on-device storage.
    AuthService.instance.resetForTesting();
    final relaunched = AppState();
    await tester.runAsync(relaunched.bootstrap);

    expect(relaunched.isSignedIn, isTrue);
    await pumpGate(tester, relaunched);
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('signing out sends the app straight back to the login screen', (
    tester,
  ) async {
    final app = await boot(tester, {
      _kSignedInAt: DateTime.now().millisecondsSinceEpoch,
    });
    await pumpGate(tester, app);
    expect(find.byType(HomeShell), findsOneWidget);

    await tester.runAsync(app.signOut);
    await tester.pumpAndSettle();

    expect(app.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a session that runs out while the app is open is revalidated', (
    tester,
  ) async {
    // The app was opened inside the day, then left in the background until
    // the day was over: revalidateSession (called on resume) must close it.
    final app = await boot(tester, {
      _kSignedInAt: DateTime.now().millisecondsSinceEpoch,
    });
    await pumpGate(tester, app);
    expect(find.byType(HomeShell), findsOneWidget);

    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    await tester.runAsync(
      () => prefs!.setInt(
        _kSignedInAt,
        DateTime.now()
            .subtract(const Duration(hours: 30))
            .millisecondsSinceEpoch,
      ),
    );
    await tester.runAsync(app.revalidateSession);
    await tester.pumpAndSettle();

    expect(app.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  // ---- The credential check itself --------------------------------------

  test('credentials are matched exactly, bar case/spaces in the username', () {
    final auth = AuthService.instance;
    expect(auth.credentialsMatch(_user, _pass), isTrue);
    expect(auth.credentialsMatch('  Snoopy ', _pass), isTrue);
    expect(auth.credentialsMatch(_user, '1qaz!qaz'), isFalse);
    expect(auth.credentialsMatch(_user, ' 1qaz!QAZ'), isFalse);
    expect(auth.credentialsMatch('snoop', _pass), isFalse);
    expect(auth.credentialsMatch('', ''), isFalse);
  });
}
