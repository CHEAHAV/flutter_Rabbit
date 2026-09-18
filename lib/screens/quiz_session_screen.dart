import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/question.dart';
import '../state/app_state.dart';
import '../state/exam_session.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/option_tile.dart';
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
  late ExamSession _session;
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final questions = widget.overrideQuestions ?? _buildQuestionPool(app);
    _session = ExamSession(config: widget.config, questions: questions);
    _session.onTimeExpired = _handleTimeExpired;
    _session.onLowTimeWarning = _handleLowTime;
  }

  List<Question> _buildQuestionPool(AppState app) {
    final pool = <Question>[];
    for (final part in app.parts) {
      if (widget.config.partIds.contains(part.id)) {
        pool.addAll(part.questions);
      }
    }
    if (widget.config.shuffleQuestions) {
      pool.shuffle(Random());
    }
    final count = widget.config.questionCount;
    if (count > 0 && count < pool.length) {
      return pool.sublist(0, count);
    }
    return pool;
  }

  void _handleLowTime() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏰ សល់ពេលត្រឹមតែ ៥ នាទីទៀតប៉ុណ្ណោះ!')),
    );
  }

  void _handleTimeExpired() {
    if (!mounted) return;
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
                  return _EmptyPool(onBack: () => Navigator.of(context).pop());
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
                                      TextButton.icon(
                                        onPressed: session.toggleFlag,
                                        icon: Icon(
                                          session.current.flagged
                                              ? Icons.flag_rounded
                                              : Icons.outlined_flag_rounded,
                                          size: 16,
                                          color: session.current.flagged
                                              ? AppColors.amber
                                              : AppColors.slate,
                                        ),
                                        label: Text(
                                          session.current.flagged
                                              ? 'បានចំណាំ'
                                              : 'ចំណាំទុក',
                                          style: TextStyle(
                                            color: session.current.flagged
                                                ? AppColors.amber
                                                : AppColors.slate,
                                            fontSize: 11.5,
                                          ),
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
                                    4,
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
      onTap: locked ? null : () => _handleSelect(session, index),
    );
  }

  void _handleSelect(ExamSession session, int index) {
    final correct = index == session.current.question.answerIndex;
    session.selectOption(index);
    if (!widget.config.instantFeedback) return;
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
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('បន្តប្រឡង'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
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
                    onPressed: () => Navigator.of(ctx).pop(),
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
                  _legend(AppColors.amber, 'ចំណាំ'),
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
                      border = AppColors.amber;
                    } else if (a.isAnswered) {
                      border = AppColors.emerald;
                    }
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
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
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('ពិនិត្យមើលទៀត'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
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
    final app = context.read<AppState>();
    await app.progress.recordResult(result);
    app.refresh();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
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
                onPressed: onExit,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Center(
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
              IconButton(
                onPressed: onGrid,
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
                border = AppColors.amber;
              }
              return InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => session.goTo(i),
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
                onPressed: session.isFirst ? null : session.prev,
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
                onPressed: session.isLast ? onSubmit : session.next,
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
            ElevatedButton(onPressed: onBack, child: const Text('ត្រឡប់ក្រោយ')),
          ],
        ),
      ),
    );
  }
}
