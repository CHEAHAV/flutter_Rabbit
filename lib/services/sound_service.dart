import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Every sound effect the app can play. Files live in `assets/sounds/`
/// (regenerate with `python tool/generate_sounds.py`).
enum AppSound {
  /// Generic button press.
  tap('tap.wav', 0.55),

  /// Choosing an option, ticking a subject, picking a filter.
  select('select.wav', 0.6),
  toggleOn('toggle_on.wav', 0.6),
  toggleOff('toggle_off.wav', 0.6),
  correct('correct.wav', 1.0),
  wrong('wrong.wav', 0.9),
  success('success.wav', 1.0),
  fail('fail.wav', 0.9),
  warning('warning.wav', 0.8);

  const AppSound(this.file, this.gain);

  /// File name inside `assets/sounds/`.
  final String file;

  /// Relative loudness of this effect (0..1) so tiny UI clicks sit well below
  /// the feedback chimes at the same volume setting.
  final double gain;
}

/// The thing that actually makes noise. Split out so [SoundService] logic
/// (mute, volume curve, error handling) is testable without a device.
abstract class SoundBackend {
  Future<void> init();
  Future<void> play(AppSound sound, double volume);
  Future<void> dispose();
}

/// Plays effects through `audioplayers`, one pre-loaded low-latency player per
/// sound so a tap responds instantly and different sounds can overlap.
class AudioPlayersBackend implements SoundBackend {
  final Map<AppSound, AudioPlayer> _players = {};

  @override
  Future<void> init() async {
    // UI sounds must never interrupt the user's music/podcast, and should
    // follow the normal media volume on Android (hardware volume keys) and the
    // silent switch on iOS - the same behaviour as any well-behaved app.
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
    // Copy every asset out of the bundle up-front so the first tap is not slow.
    await AudioCache.instance.loadAll([
      for (final s in AppSound.values) 'sounds/${s.file}',
    ]);
    for (final s in AppSound.values) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('sounds/${s.file}'));
      _players[s] = player;
    }
  }

  @override
  Future<void> play(AppSound sound, double volume) async {
    final player = _players[sound];
    if (player == null) return;
    await player.stop(); // restart cleanly if it is still ringing
    await player.setVolume(volume);
    await player.resume();
  }

  @override
  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}

/// App-wide sound effects with a master on/off switch and volume level.
///
/// All `play*` methods are fire-and-forget and can never throw: if audio is
/// muted, not initialised yet, or the platform has no audio support, they
/// silently do nothing, so a sound problem can never break a button press.
class SoundService {
  SoundService._(this._backend);
  static final SoundService instance = SoundService._(AudioPlayersBackend());

  /// A service with its own backend, for tests.
  @visibleForTesting
  factory SoundService.withBackend(SoundBackend backend) =>
      SoundService._(backend);

  static const double defaultVolume = 0.7;

  /// Swaps the audio backend and resets to "not loaded", so widget tests can
  /// record what the real UI plays without needing an audio device.
  @visibleForTesting
  void useBackendForTesting(SoundBackend backend) {
    _backend = backend;
    _ready = false;
    _initFuture = null;
  }

  SoundBackend _backend;
  bool _ready = false;
  Future<void>? _initFuture;
  bool _enabled = true;
  double _volume = defaultVolume;

  bool get isReady => _ready;

  /// Master switch. When false nothing plays.
  bool get enabled => _enabled;

  /// Slider position, 0.0 (silent) to 1.0 (loudest).
  double get volume => _volume;

  /// True when a sound would actually be audible right now.
  bool get audible => _enabled && _volume > 0;

  void configure({required bool enabled, required double volume}) {
    _enabled = enabled;
    _volume = volume.clamp(0.0, 1.0).toDouble();
  }

  /// Loads the sounds. Safe to call repeatedly; never throws. If the platform
  /// has no audio support the service just stays silent.
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    try {
      await _backend.init().timeout(const Duration(seconds: 8));
      _ready = true;
    } catch (e) {
      debugPrint('SoundService: audio unavailable, running silent ($e)');
    }
  }

  /// Maps the linear slider to an amplitude. Loudness is perceived roughly
  /// logarithmically, so a linear amplitude makes the top half of a slider
  /// feel identical; a power curve spreads the change evenly.
  @visibleForTesting
  static double amplitudeFor(double slider) =>
      math.pow(slider.clamp(0.0, 1.0), 1.6).toDouble();

  void play(AppSound sound) {
    if (!_ready || !audible) return;
    final amplitude = (amplitudeFor(_volume) * sound.gain).clamp(0.0, 1.0);
    try {
      unawaited(
        _backend
            .play(sound, amplitude)
            .catchError((Object e) => debugPrint('SoundService: $sound: $e')),
      );
    } catch (e) {
      debugPrint('SoundService: $sound: $e');
    }
  }

  // Intent-named helpers keep call sites readable.
  void tap() => play(AppSound.tap);
  void select() => play(AppSound.select);
  void toggle(bool on) => play(on ? AppSound.toggleOn : AppSound.toggleOff);
  void answer({required bool correct}) =>
      play(correct ? AppSound.correct : AppSound.wrong);
  void result({required bool passed}) =>
      play(passed ? AppSound.success : AppSound.fail);
  void warning() => play(AppSound.warning);

  Future<void> dispose() async {
    _ready = false;
    try {
      await _backend.dispose();
    } catch (_) {}
  }
}

/// Short alias so call sites read `sfx.tap()`.
SoundService get sfx => SoundService.instance;
