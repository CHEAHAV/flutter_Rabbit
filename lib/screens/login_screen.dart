import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shake_widget.dart';

/// The private-app gate. Only the one account in [AuthService] gets in, and a
/// successful sign-in lasts a day, so this screen is only seen on the first
/// launch and once a day afterwards.
///
/// There is no navigation out of here: `app.dart` watches [AppState.isSignedIn]
/// and swaps this screen for the app the moment the sign-in succeeds.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  final _shakeKey = GlobalKey<ShakeWidgetState>();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final user = _userCtrl.text;
    final pass = _passCtrl.text;

    if (user.trim().isEmpty || pass.isEmpty) {
      _fail('សូមបញ្ចូលឈ្មោះអ្នកប្រើ និងពាក្យសម្ងាត់');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await context.read<AppState>().signIn(user, pass);
    if (!mounted) return;

    if (ok) {
      // Nothing to navigate to: app.dart rebuilds onto the app itself as soon
      // as the session exists. Just stop the spinner in case this screen is
      // still on screen for a frame.
      sfx.answer(correct: true);
      setState(() => _busy = false);
      return;
    }

    setState(() => _busy = false);
    _fail('ឈ្មោះអ្នកប្រើ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ');
    _passCtrl.clear();
    _passFocus.requestFocus();
  }

  void _fail(String message) {
    HapticFeedback.mediumImpact();
    sfx.warning();
    setState(() => _error = message);
    _shakeKey.currentState?.shake();
  }

  @override
  Widget build(BuildContext context) {
    final onDeep = Colors.white;
    return Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _logo(),
                        const SizedBox(height: 18),
                        Text(
                          'Rabbit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onDeep,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'កម្មវិធីឯកជន · សូមចូលប្រើដើម្បីបន្ត',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFDCEEE3),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ShakeWidget(key: _shakeKey, child: _card()),
                        const SizedBox(height: 18),
                        const Text(
                          'ចូលម្ដងរួច អាចប្រើបាន ១ ថ្ងៃ ដោយមិនបាច់ចូលម្ដងទៀត',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFA9CDBA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _logo() {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('🐇', style: TextStyle(fontSize: 40)),
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ចូលគណនី',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          _label('ឈ្មោះអ្នកប្រើ'),
          const SizedBox(height: 6),
          TextField(
            controller: _userCtrl,
            focusNode: _userFocus,
            enabled: !_busy,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            onSubmitted: (_) => _passFocus.requestFocus(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: _fieldDecoration(
              hint: 'username',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          _label('ពាក្យសម្ងាត់'),
          const SizedBox(height: 6),
          TextField(
            controller: _passCtrl,
            focusNode: _passFocus,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: _fieldDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                  color: AppColors.slate,
                ),
                tooltip: _obscure ? 'បង្ហាញពាក្យសម្ងាត់' : 'លាក់ពាក្យសម្ងាត់',
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.redBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.onEmerald,
                disabledBackgroundColor: AppColors.emerald.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onEmerald,
                      ),
                    )
                  : const Text(
                      'ចូលប្រើ',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AppColors.slate,
    ),
  );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
      ),
      prefixIcon: Icon(icon, size: 19, color: AppColors.slate),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(AppColors.line, 1),
      disabledBorder: border(AppColors.line, 1),
      focusedBorder: border(AppColors.emerald, 1.6),
      errorBorder: border(AppColors.redBorder, 1),
    );
  }
}
