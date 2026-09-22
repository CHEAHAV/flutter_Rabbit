import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/question.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../state/exam_session.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/option_tile.dart';
import '../widgets/save_snackbar.dart';
import '../widgets/shake_widget.dart';
import 'result_screen.dart';

class QuizSessionScreen extends StatefulWidget {
  final ExamConfig config;
  final List<Question>? overrideQuestions;

  const QuizSessionScreen({
    super.key,
    required this.config,
    this.overrideQuestions,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  late AppState _app;
  late ExamSession _session;
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  /// True when the selected subjects do have questions, but the user has
  /// already answered every one of them. Told apart from a genuinely empty
  /// selection so the screen can offer to start the subject over instead of
  /// just saying there is nothing here.
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _startSession();
  }

  /// Builds the pool and opens a fresh [ExamSession] over it.
  void _startSession() {
    final questions = widget.overrideQuestions ?? _buildQuestionPool(_app);
    _exhausted =
        widget.overrideQuestions == null &&
        questions.isEmpty &&
        _app.fullPool(widget.config.partIds).isNotEmpty;
    _session = ExamSession(config: widget.config, questions: questions);
    // A question the user saved in an earlier session is still saved, so it
    // opens showing "បានរក្សាទុក" and pressing the button unsaves it.
    _session.syncFlags(_app.progress.isBookmarked);
    _session.onTimeExpired = _handleTimeExpired;
    _session.onLowTimeWarning = _handleLowTime;
  }

  /// Saves or unsaves [question], which is the one on screen when the button
  /// is pressed and stays the one an undo puts back even if the user has paged
  /// on since.
  ///
  /// The save is written to the notebook first and the session flag is then set
  /// from what the notebook says, so the button, the question grid and the
  /// notebook's saved list are always showing the same one fact. A save lasts
  /// until the user presses the button again - finishing the session, quitting
  /// it or closing the app never clears it.
  Future<void> _toggleSave(ExamSession session, Question question) async {
    sfx.tap();
    final saved = await _app.progress.toggleBookmark(question.uid);
    if (!mounted) return;
    session.setFlagFor(question.uid, saved);
    // The notebook tab reads the saved list straight out of ProgressService,
    // so it has to be told the list moved.
    _app.refresh();
    showSaveChoiceSnackBar(
      context,
      saved: saved,
      onUndo: () => _toggleSave(session, question),
    );
  }

  /// The questions this session will ask.
  ///
  /// Only questions the user has never answered are eligible: finishing 50 of
  /// a 200-question subject and coming back leaves a pool of the other 150,
  /// and the session is drawn from those. When fewer are left than the session
  /// asked for, the session is simply that much shorter - it is never padded
  /// out with questions that have already been answered.
  List<Question> _buildQuestionPool(AppState app) {
    final pool = app.unansweredPool(widget.config.partIds);
    if (widget.config.shuffleQuestions) {
      pool.shuffle(Random());
    }
    final count = widget.config.questionCount;
    if (count > 0 && count < pool.length) {
      return pool.sublist(0, count);
    }
    return pool;
  }

  /// Forgets the answered questions of this session's subjects and starts
  /// again over the full bank. Reached only from [_ExhaustedPool], once every
  /// question really has been answered.
  Future<void> _restartFromScratch() async {
    await _app.progress.resetAnswered(widget.config.partIds);
    _app.refresh();
    if (!mounted) return;
    _session.dispose();
    setState(_startSession);
  }

  void _handleLowTime() {
    if (!mounted) return;
    sfx.warning();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏰ សល់ពេលត្រឹមតែ ៥ នាទីទៀតប៉ុណ្ណោះ!')),
    );
  }

  void _handleTimeExpired() {
    if (!mounted) return;
    sfx.warning();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ពេលវេលាអស់ហើយ — កំពុងដាក់ស្នើចម្លើយស្វ័យប្រវត្តិ'),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _submit();
    });
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _session,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Consumer<ExamSession>(
              builder: (context, session, _) {
                if (session.total == 0) {
                  return _exhausted
                      ? _ExhaustedPool(
                          answered: _app.fullPool(widget.config.partIds).length,
                          onRestart: _restartFromScratch,
                          onBack: () => Navigator.of(context).pop(),
                        )
                      : _EmptyPool(onBack: () => Navigator.of(context).pop());
                }
                final app = context.read<AppState>();
                final part = app.repo.partById(session.current.question.partId);
                return Column(
                  children: [
                    _Header(
                      session: session,
                      onExit: _confirmExit,
                      onGrid: () => _openGrid(context, session),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShakeWidget(
                              key: _shakeKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.mint,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            part.titleKm,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.emerald,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _SaveButton(
                                        saved: app.progress.isBookmarked(
                                          session.current.question.uid,
                                        ),
                                        onPressed: () => _toggleSave(
                                          session,
                                          session.current.question,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    session.current.question.text,
                                    style: TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.75,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...List.generate(
                                    session.current.question.options.length,
                                    (i) => _buildOption(session, i),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            _QuickNavigator(session: session),
                          ],
                        ),
                      ),
                    ),
                    _Footer(session: session, onSubmit: _submit),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(ExamSession session, int index) {
    final attempt = session.current;
    final showFeedback = widget.config.instantFeedback && attempt.isAnswered;
    OptionState state = OptionState.neutral;
    if (showFeedback) {
      if (index == attempt.question.answerIndex) {
        state = OptionState.correct;
      } else if (index == attempt.selectedIndex) {
        state = OptionState.wrong;
      }
    } else if (attempt.selectedIndex == index) {
      state = OptionState.selected;
    }
    final locked = showFeedback;
    return OptionTile(
      index: index,
      text: attempt.question.options[index],
      state: state,
      labels: attempt.question.optionLabels,
      onTap: locked ? null : () => _handleSelect(session, index),
    );
  }

  void _handleSelect(ExamSession session, int index) {
    final correct = index == session.current.question.answerIndex;
    final uid = session.current.question.uid;
    session.selectOption(index);
    // Remembered straight away rather than at submit time: a session the user
    // walks out of must still count as "these questions are used up",
    // otherwise quitting halfway would serve them all over again.
    unawaited(_app.progress.markAnswered([uid]));
    if (!widget.config.instantFeedback) {
      sfx.select();
      return;
    }
    sfx.answer(correct: correct);
    if (correct) {
      HapticFeedback.lightImpact();
      showCelebrationOverlay(context);
    } else {
      HapticFeedback.vibrate();
      _shakeKey.currentState?.shake();
    }
  }

  void _confirmExit() async {
    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ចាកចេញពីការប្រឡង?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'ចម្លើយរបស់អ្នកក្នុងវគ្គនេះនឹងមិនត្រូវបានរក្សាទុកទេ ប្រសិនបើអ្នកចាកចេញឥឡូវនេះ។',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.slate,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop(false);
                    },
                    child: const Text('បន្តប្រឡង'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                    ),
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text('ចាកចេញ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openGrid(BuildContext context, ExamSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            18 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'បញ្ជីសំណួរ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  _legend(AppColors.emerald, 'ឆ្លើយរួច'),
                  _legend(AppColors.gold, 'បានរក្សាទុក'),
                  _legend(AppColors.line, 'មិនទាន់ឆ្លើយ'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: GridView.builder(
                  itemCount: session.total,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, i) {
                    final a = session.attempts[i];
                    final isCurrent = i == session.currentIndex;
                    Color bg = AppColors.card;
                    Color fg = AppColors.ink;
                    Color border = AppColors.line;
                    if (isCurrent) {
                      bg = AppColors.emerald;
                      fg = AppColors.onEmerald;
                      border = AppColors.emerald;
                    } else if (a.flagged) {
                      border = AppColors.gold;
                    } else if (a.isAnswered) {
                      border = AppColors.emerald;
                    }
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        sfx.tap();
                        session.goTo(i);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: border,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          kh(i + 1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10.5, color: AppColors.slate)),
      ],
    );
  }

  void _submit() async {
    final session = _session;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ដាក់ស្នើចម្លើយ?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'អ្នកបានឆ្លើយ ${kh(session.answeredCount)}/${kh(session.total)} សំណួរ'
              '${session.total - session.answeredCount > 0 ? " (នៅសល់ ${kh(session.total - session.answeredCount)} មិនទាន់ឆ្លើយ)" : ""}។',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.slate,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop(false);
                    },
                    child: const Text('ពិនិត្យមើលទៀត'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text('ដាក់ស្នើ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = session.finish();
    await _app.progress.recordResult(result);
    _app.refresh();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
    );
  }
}

/// The "save this question" control above the question text.
///
/// [saved] comes from the persisted notebook, not from the live session, so
/// what the button says is what the notebook holds. Never instantiate it with
/// `const`: its build reads [AppColors], the palette the theme switch mutates
/// in place, and a const instance would keep the colours of the theme it was
/// first built under.
class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onPressed;

  const _SaveButton({required this.saved, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = saved ? AppColors.gold : AppColors.slate;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 16,
        color: color,
      ),
      label: Text(
        saved ? 'បានរក្សាទុក' : 'ចំណាំទុក',
        style: TextStyle(color: color, fontSize: 11.5),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ExamSession session;
  final VoidCallback onExit;
  final VoidCallback onGrid;
  const _Header({
    required this.session,
    required this.onExit,
    required this.onGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  sfx.tap();
                  onExit();
                },
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Center(
                  // Shrinks (never overflows) on very narrow screens.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: session.lowTime
                            ? AppColors.redBg
                            : AppColors.amberBg,
                        border: Border.all(
                          color: session.lowTime
                              ? AppColors.redBorder
                              : AppColors.amberBorder,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: session.lowTime
                                ? AppColors.red
                                : (AppColors.isDark
                                      ? AppColors.amber
                                      : const Color(0xFF875500)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            session.remaining == null
                                ? khDuration(session.elapsed)
                                : khDuration(session.remaining!),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: session.lowTime
                                  ? AppColors.red
                                  : (AppColors.isDark
                                        ? AppColors.amber
                                        : const Color(0xFF875500)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // No `const`: its build() reads AppColors.
              _SoundButton(),
              IconButton(
                onPressed: () {
                  sfx.tap();
                  onGrid();
                },
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${kh(session.currentIndex + 1)}/${kh(session.total)}',
              style: TextStyle(fontSize: 11, color: AppColors.slate),
            ),
          ),
          ClipRRect(
            child: LinearProgressIndicator(
              value: (session.currentIndex + 1) / session.total,
              minHeight: 3,
              backgroundColor: AppColors.line,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick mute / unmute speaker in the quiz header, so sound can be switched
/// off mid-exam without leaving the session.
class _SoundButton extends StatelessWidget {
  const _SoundButton();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final muted = app.soundMuted;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: muted ? 'បើកសំឡេង' : 'បិទសំឡេង',
      onPressed: () {
        HapticFeedback.selectionClick();
        app.setSoundEnabled(muted);
      },
      icon: Icon(
        muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        color: muted ? AppColors.muted : null,
      ),
    );
  }
}

class _QuickNavigator extends StatelessWidget {
  final ExamSession session;
  const _QuickNavigator({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'រុករកលឿន',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: session.total,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final a = session.attempts[i];
              final isCurrent = i == session.currentIndex;
              Color bg = AppColors.card;
              Color fg = AppColors.ink;
              Color border = AppColors.line;
              if (isCurrent) {
                bg = AppColors.emerald;
                fg = AppColors.onEmerald;
                border = AppColors.emerald;
              } else if (a.isAnswered) {
                border = AppColors.emerald;
              } else if (a.flagged) {
                border = AppColors.gold;
              }
              return InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () {
                  sfx.tap();
                  session.goTo(i);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    kh(i + 1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final ExamSession session;
  final VoidCallback onSubmit;
  const _Footer({required this.session, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: session.isFirst
                    ? null
                    : () {
                        sfx.tap();
                        session.prev();
                      },
                child: const Text('← សំណួរមុន'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    'ឆ្លើយរួច',
                    style: TextStyle(fontSize: 9.5, color: AppColors.slate),
                  ),
                  Text(
                    '${kh(session.answeredCount)}/${kh(session.total)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  sfx.tap();
                  if (session.isLast) {
                    onSubmit();
                  } else {
                    session.next();
                  }
                },
                child: Text(session.isLast ? 'ដាក់ស្នើ →' : 'បន្ទាប់ →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPool extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyPool({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: AppColors.muted),
            const SizedBox(height: 14),
            const Text(
              'គ្មានសំណួរសម្រាប់ការជ្រើសរើសនេះទេ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'សូមជ្រើសរើសមុខវិជ្ជាផ្សេងទៀត ឬបន្ថយលក្ខខណ្ឌ',
              style: TextStyle(fontSize: 12, color: AppColors.slate),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                sfx.tap();
                onBack();
              },
              child: const Text('ត្រឡប់ក្រោយ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when every question of the chosen subjects has already been
/// answered. The pool deliberately never recycles a question on its own, so
/// going round again has to be the user's own decision - and it is offered
/// right here, rather than leaving them on a dead end.
class _ExhaustedPool extends StatelessWidget {
  final int answered;
  final Future<void> Function() onRestart;
  final VoidCallback onBack;

  const _ExhaustedPool({
    required this.answered,
    required this.onRestart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 44,
              color: AppColors.emerald,
            ),
            const SizedBox(height: 14),
            Text(
              'អ្នកបានឆ្លើយគ្រប់សំណួរហើយ! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'សំណួរទាំង ${kh(answered)} ក្នុងការជ្រើសរើសនេះ អ្នកបានឆ្លើយរួចរាល់ហើយ។ '
              'មិនមានសំណួរថ្មីណាមួយទៀតទេ។',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.slate,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey('restart-exhausted-pool'),
                onPressed: () {
                  sfx.tap();
                  onRestart();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'ចាប់ផ្ដើមឡើងវិញពីដើម',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  sfx.tap();
                  onBack();
                },
                child: const Text(
                  'ជ្រើសមុខវិជ្ជាផ្សេង',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
