import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gate that keeps the app private: only the one account below may use it,
/// and a successful sign-in is remembered on-device for [sessionDuration]
/// (one day) so the user is not asked again every time they open the app.
///
/// The session is a timestamp, not a flag: [_isFresh] re-reads it on every
/// launch and on every resume, so the moment 24 hours have passed since the
/// sign-in the user is sent back to the login screen.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// When the current session was opened (epoch milliseconds).
  static const _kSignedInAt = 'rabbit.auth.signedInAt';

  /// Who signed in - kept so a future second account cannot inherit the
  /// session of the first one.
  static const _kUsername = 'rabbit.auth.username';

  /// How long one successful login is trusted for. After this, credentials
  /// must be typed again.
  static const Duration sessionDuration = Duration(days: 1);

  /// The single account allowed into the app, base64 so the pair is not
  /// readable in a plain `strings` dump of the built binary. This is
  /// obfuscation, not security: anything shipped inside a client app can be
  /// recovered by a determined reader. It is enough to keep the app private
  /// from ordinary users, which is what it is for.
  static const _encodedUsername = 'c25vb3B5'; // snoopy
  static const _encodedPassword = 'MXFheiFRQVo='; // 1qaz!QAZ

  static String get _expectedUsername =>
      utf8.decode(base64Decode(_encodedUsername));
  static String get _expectedPassword =>
      utf8.decode(base64Decode(_encodedPassword));

  SharedPreferences? _prefs;
  bool _ready = false;
  DateTime? _signedInAt;

  /// True while an unexpired session is on record. Read by the UI to decide
  /// between the login screen and the app itself.
  bool get isSignedIn => _signedInAt != null;

  /// The signed-in account name, or null when signed out.
  String? get currentUser => _signedInAt == null
      ? null
      : (_prefs?.getString(_kUsername) ?? _expectedUsername);

  /// When the current session stops being valid, or null when signed out.
  DateTime? get expiresAt => _signedInAt?.add(sessionDuration);

  /// How much of the current session is left, or null when signed out.
  /// Never negative: an expired session is cleared rather than reported.
  Duration? get timeLeft {
    final end = expiresAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Forces the next [init] to re-read storage. Tests only: the service is a
  /// singleton, so without this one test's session leaks into the next.
  @visibleForTesting
  void resetForTesting() {
    _ready = false;
    _signedInAt = null;
    _prefs = null;
  }

  /// Loads the stored session and drops it if it has expired. Safe to call
  /// more than once; later calls just re-check the clock.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _ready = true;
    await refresh();
  }

  /// Re-checks the stored session against the clock and clears it when it has
  /// run out. Returns true when a valid session remains.
  ///
  /// Called at launch and whenever the app comes back to the foreground, so a
  /// session cannot outlive its day just because the app was left open.
  Future<bool> refresh() async {
    if (!_ready) return false;
    final stored = _prefs?.getInt(_kSignedInAt);
    if (stored == null) {
      _signedInAt = null;
      return false;
    }
    final at = DateTime.fromMillisecondsSinceEpoch(stored);
    if (_isFresh(at)) {
      _signedInAt = at;
      return true;
    }
    // Expired (or the device clock moved backwards past it): forget it, so the
    // login screen is shown and nothing is left to re-validate later.
    _signedInAt = null;
    await _clear();
    return false;
  }

  /// A session counts only while it is between its own start and one day
  /// after it. A timestamp in the future means the device clock was moved, and
  /// is treated as invalid rather than trusted indefinitely.
  bool _isFresh(DateTime at) {
    final now = DateTime.now();
    if (at.isAfter(now)) return false;
    return now.difference(at) < sessionDuration;
  }

  /// Whether [username]/[password] are the credentials of the one allowed
  /// account. The username ignores case and surrounding spaces (phone
  /// keyboards love to capitalise and to add a trailing space); the password
  /// is compared exactly.
  bool credentialsMatch(String username, String password) {
    final user = username.trim();
    return user.toLowerCase() == _expectedUsername.toLowerCase() &&
        password == _expectedPassword;
  }

  /// Checks the credentials and, when they match, opens a session that lasts
  /// [sessionDuration]. Returns true on success.
  Future<bool> signIn(String username, String password) async {
    if (!credentialsMatch(username, password)) return false;
    _prefs ??= await SharedPreferences.getInstance();
    _ready = true;
    final now = DateTime.now();
    await _prefs!.setInt(_kSignedInAt, now.millisecondsSinceEpoch);
    await _prefs!.setString(_kUsername, _expectedUsername);
    _signedInAt = now;
    return true;
  }

  /// Ends the session immediately; the next launch asks for credentials.
  Future<void> signOut() async {
    _signedInAt = null;
    await _clear();
  }

  Future<void> _clear() async {
    await _prefs?.remove(_kSignedInAt);
    await _prefs?.remove(_kUsername);
  }
}
