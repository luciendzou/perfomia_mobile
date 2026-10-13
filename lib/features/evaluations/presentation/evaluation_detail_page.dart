import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/evaluation_service.dart';

class EvaluationDetailPage extends StatefulWidget {
  const EvaluationDetailPage({
    super.key,
    required this.session,
    required this.evaluationId,
  });
  final AuthSession session;
  final String evaluationId;
  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState extends State<EvaluationDetailPage> {
  late final EvaluationService _service;
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _answers = <String, TextEditingController>{};
  final _managerComment = TextEditingController();
  final _adminComment = TextEditingController();
  final _managerCriterionCommentControllers = <String, TextEditingController>{};
  List<Map<String, dynamic>> _managerCriteria = const [];
  final _managerRatings = <String, int>{};
  final _managerCriterionComments = <String, String>{};
  int _managerMinScore = 1;
  int _managerMaxScore = 5;
  bool _managerCriteriaLoading = false;

  @override
  void initState() {
    super.initState();
    _service = EvaluationService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  @override
  void dispose() {
    for (final controller in _answers.values) {
      controller.dispose();
    }
    _managerComment.dispose();
    _adminComment.dispose();
    for (final controller in _managerCriterionCommentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.show(widget.evaluationId);
      final questions = data['questions'] is List
          ? data['questions'] as List
          : const [];
      final answers = data['answers'] is List
          ? data['answers'] as List
          : const [];
      final saved = <String, String>{};
      for (final answer in answers.whereType<Map>()) {
        saved['${answer['question_id']}'] = '${answer['answer'] ?? ''}';
      }
      for (final question in questions.whereType<Map>()) {
        final id = '${question['id']}';
        _answers.putIfAbsent(
          id,
          () => TextEditingController(text: saved[id] ?? ''),
        );
      }
      if (mounted) setState(() => _data = data);
      final workflow = data['evaluation'] is Map
          ? (data['evaluation'] as Map)['workflow']
          : null;
      final actions = workflow is Map && workflow['allowed_actions'] is List
          ? (workflow['allowed_actions'] as List).map((item) => '$item')
          : const <String>[];
      if (actions.contains('submit_manager_review')) {
        await _loadManagerCriteria();
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).evaluationDetailLoadError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get _evaluation => _data?['evaluation'] is Map
      ? Map<String, dynamic>.from(_data!['evaluation'] as Map)
      : (_data ?? <String, dynamic>{});

  String _statusLabel(String value, BuildContext context) =>
      {
        'not_started': AppLocalizations.of(context).evaluationNotStarted,
        'self_in_progress': AppLocalizations.of(context).evaluationInProgress,
        'manager_review_pending': AppLocalizations.of(
          context,
        ).managerReviewPending,
        'ai_scored': AppLocalizations.of(context).aiScoreAvailable,
        'manager_reviewed': AppLocalizations.of(context).managerReviewed,
        'admin_review_pending': AppLocalizations.of(context).adminReviewPending,
        'completed': AppLocalizations.of(context).completedEvaluations,
      }[value] ??
      value.replaceAll('_', ' ');

  List<String> get _actions {
    final workflow = _evaluation['workflow'];
    final actions = workflow is Map && workflow['allowed_actions'] is List
        ? workflow['allowed_actions'] as List
        : const [];
    return actions.map((item) => '$item').toList();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      await _load();
      if (mounted) showAppSuccess(success);
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitAnswers() {
    if (!_actions.contains('submit_answers')) return Future.value();
    return _run(
      () => _service.submitAnswers(
        widget.evaluationId,
        _answers.entries
            .map(
              (entry) => {
                'question_id': entry.key,
                'answer': entry.value.text.trim(),
              },
            )
            .toList(),
      ),
      AppLocalizations.of(context).answersSent,
    );
  }

  Future<void> _managerReview() async {
    if (!_actions.contains('submit_manager_review')) return;
    if (_managerCriteriaLoading) return;
    if (_managerCriteria.isEmpty) {
      showAppError(AppLocalizations.of(context).noCriteriaAvailable);
      return;
    }
    final message = AppLocalizations.of(context).managerFeedbackSaved;
    final submitted = await _showManagerReview();
    if (!submitted) return;
    await _run(
      () => _service.submitManagerFeedback(
        widget.evaluationId,
        ratings: _managerCriteria
            .map(
              (criterion) => {
                'criterion_id': '${criterion['id']}',
                'score': _managerRatings['${criterion['id']}'],
                if ((_managerCriterionComments['${criterion['id']}'] ?? '')
                    .trim()
                    .isNotEmpty)
                  'comment': _managerCriterionComments['${criterion['id']}']
                      ?.trim(),
              },
            )
            .toList(),
        comment: _managerComment.text,
      ),
      message,
    );
  }

  Future<void> _loadManagerCriteria() async {
    if (!mounted) return;
    setState(() => _managerCriteriaLoading = true);
    try {
      final result = await _service.fetchManagerCriteria(widget.evaluationId);
      final ratings = <String, int>{};
      final comments = <String, String>{};
      for (final item in result.currentRatings) {
        final id = '${item['criterion_id']}';
        final score = int.tryParse('${item['score']}');
        if (score != null) ratings[id] = score;
        comments[id] = item['comment']?.toString() ?? '';
      }
      if (mounted) {
        setState(() {
          _managerCriteria = result.items;
          _managerRatings
            ..clear()
            ..addAll(ratings);
          _managerCriterionComments
            ..clear()
            ..addAll(comments);
          _managerMinScore = result.minScore;
          _managerMaxScore = result.maxScore;
        });
        for (final entry in comments.entries) {
          final controller = _managerCriterionCommentControllers.putIfAbsent(
            entry.key,
            () => TextEditingController(),
          );
          controller.text = entry.value;
        }
      }
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    } finally {
      if (mounted) setState(() => _managerCriteriaLoading = false);
    }
  }

  Future<bool> _showManagerReview() async {
    _managerComment.text = '';
    return await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(AppLocalizations.of(context).managerRating),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(AppLocalizations.of(context).rateEachCriterion),
                      const SizedBox(height: 16),
                      ..._managerCriteria.map((criterion) {
                        final id = '${criterion['id']}';
                        final selected = _managerRatings[id];
                        final max =
                            int.tryParse('${criterion['max_score']}') ??
                            _managerMaxScore;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${criterion['label'] ?? AppLocalizations.of(context).criterion} ($_managerMinScore-$max)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if ('${criterion['description'] ?? ''}'
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${criterion['description']}',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (
                                    var score = _managerMinScore;
                                    score <= max;
                                    score++
                                  )
                                    ChoiceChip(
                                      label: Text('$score'),
                                      selected: selected == score,
                                      onSelected: (_) {
                                        setState(
                                          () => _managerRatings[id] = score,
                                        );
                                        setDialogState(() {});
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _managerCriterionCommentControllers
                                    .putIfAbsent(
                                      id,
                                      () => TextEditingController(
                                        text:
                                            _managerCriterionComments[id] ?? '',
                                      ),
                                    ),
                                onChanged: (value) =>
                                    _managerCriterionComments[id] = value,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(
                                    context,
                                  ).criterionComment,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextField(
                        controller: _managerComment,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).globalComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  onPressed: _managerRatings.length == _managerCriteria.length
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(AppLocalizations.of(context).submitRating),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _adminValidate() async {
    if (!_actions.contains('admin_validate')) return;
    final message = AppLocalizations.of(context).evaluationValidated;
    final result = await _askAdminValidation();
    if (result == null) return;
    await _run(
      () => _service.validate(
        widget.evaluationId,
        score: result.$1,
        feedback: result.$2,
      ),
      message,
    );
  }

  Future<(double, String)?> _askAdminValidation() async {
    final scoreController = TextEditingController();
    final commentController = TextEditingController(text: _adminComment.text);
    final result = await showDialog<(double, String)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).finalAdminValidation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).finalScoreOutOf100,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).validationComment,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              final score = double.tryParse(scoreController.text);
              if (score != null && score >= 0 && score <= 100) {
                Navigator.pop(context, (score, commentController.text.trim()));
              }
            },
            child: Text(AppLocalizations.of(context).validate),
          ),
        ],
      ),
    );
    scoreController.dispose();
    commentController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: _DetailSkeleton());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).evaluationTitle),
        ),
        body: Center(
          child: _ErrorState(message: _error!, onRetry: _load),
        ),
      );
    }
    final questions = _data?['questions'] is List
        ? (_data!['questions'] as List).whereType<Map>().toList()
        : const <Map>[];
    final user = _evaluation['user'] is Map
        ? Map<String, dynamic>.from(_evaluation['user'] as Map)
        : <String, dynamic>{};
    final canAnswer = _actions.contains('submit_answers');
    final feedbacks = _data?['manager_feedbacks'] is List
        ? (_data!['manager_feedbacks'] as List).whereType<Map>().toList()
        : const <Map>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).evaluationDetails),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Iconsax.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(
              '${user['full_name'] ?? user['name'] ?? AppLocalizations.of(context).unknownEvaluationUser}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${AppLocalizations.of(context).campaign} ${_evaluation['year'] ?? '-'}',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 16),
            _ScoreSummary(evaluation: _evaluation),
            const SizedBox(height: 12),
            _WorkflowCard(
              status: _statusLabel(
                '${_evaluation['status'] ?? 'not_started'}',
                context,
              ),
            ),
            if (questions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _QuestionsCard(
                questions: questions,
                answers: _answers,
                enabled: canAnswer,
                saving: _saving,
                onSubmit: _submitAnswers,
              ),
            ],
            if (_actions.contains('generate_ai_score')) ...[
              const SizedBox(height: 12),
              _ActionCard(
                title: AppLocalizations.of(context).aiAnalysis,
                description: AppLocalizations.of(
                  context,
                ).answersReadyForAnalysis,
                label: AppLocalizations.of(context).launchAnalysis,
                onTap: () => _run(
                  () => _service.generateAiScore(widget.evaluationId),
                  AppLocalizations.of(context).aiScoreGenerated,
                ),
              ),
            ],
            if (_actions.contains('submit_manager_review')) ...[
              const SizedBox(height: 12),
              _ActionCard(
                title: AppLocalizations.of(context).managerOpinion,
                description: AppLocalizations.of(
                  context,
                ).managerOpinionDescription,
                label: AppLocalizations.of(context).giveOpinion,
                onTap: _managerReview,
              ),
            ],
            if (_actions.contains('admin_validate')) ...[
              const SizedBox(height: 12),
              _ActionCard(
                title: AppLocalizations.of(context).finalValidation,
                description: AppLocalizations.of(
                  context,
                ).finalValidationDescription,
                label: AppLocalizations.of(context).validateEvaluation,
                onTap: _adminValidate,
              ),
            ],
            if (feedbacks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FeedbacksCard(items: feedbacks),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({required this.evaluation});
  final Map<String, dynamic> evaluation;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          (
            AppLocalizations.of(context).productivityScoreLabel,
            evaluation['task_score'],
          ),
          (
            AppLocalizations.of(context).aiLabel,
            evaluation['ai_interview_score'] ?? evaluation['ai_score'],
          ),
          (
            AppLocalizations.of(context).managerLabel,
            evaluation['manager_score'],
          ),
          (AppLocalizations.of(context).adminLabel, evaluation['admin_score']),
          (AppLocalizations.of(context).finalLabel, evaluation['final_score']),
        ].map((item) => _Score(label: item.$1, value: item.$2)).toList(),
      ),
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xfff8fafc),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value == null ? '-' : '$value%',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
        ),
      ],
    ),
  );
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Iconsax.route_square, color: Color(0xff2878ff)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${AppLocalizations.of(context).currentStep} : ${status.replaceAll('_', ' ')}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeedbacksCard extends StatelessWidget {
  const _FeedbacksCard({required this.items});
  final List<Map> items;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).managerOpinions,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.message_text),
              title: Text('Score : ${item['rating'] ?? '-'} / 100'),
              subtitle: Text(
                '${item['comment'] ?? item['feedback'] ?? AppLocalizations.of(context).noComment}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuestionsCard extends StatefulWidget {
  const _QuestionsCard({
    required this.questions,
    required this.answers,
    required this.enabled,
    required this.saving,
    required this.onSubmit,
  });
  final List<Map> questions;
  final Map<String, TextEditingController> answers;
  final bool enabled;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  State<_QuestionsCard> createState() => _QuestionsCardState();
}

class _QuestionsCardState extends State<_QuestionsCard> {
  int _index = 0;
  bool _reviewing = false;

  String _questionText(Map question) =>
      '${question['question'] ?? question['text'] ?? 'Question'}';

  bool _hasAnswer(int index) {
    final id = '${widget.questions[index]['id']}';
    return widget.answers[id]?.text.trim().isNotEmpty == true;
  }

  void _next() {
    if (!_hasAnswer(_index)) {
      showAppError(AppLocalizations.of(context).answerBeforeContinue);
      return;
    }
    if (_index == widget.questions.length - 1) {
      setState(() => _reviewing = true);
    } else {
      setState(() => _index += 1);
    }
  }

  void _edit(int index) => setState(() {
    _index = index;
    _reviewing = false;
  });

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return _readOnly(context);
    return _reviewing ? _review(context) : _question(context);
  }

  Widget _shell({required Widget child}) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _header(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade600)),
    ],
  );

  Widget _question(BuildContext context) {
    final question = widget.questions[_index];
    final id = '${question['id']}';
    final controller = widget.answers[id]!;
    final isLast = _index == widget.questions.length - 1;
    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            AppLocalizations.of(context).questionsTitle,
            '${AppLocalizations.of(context).question} ${_index + 1} ${AppLocalizations.of(context).ofLabel} ${widget.questions.length}',
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (_index + 1) / widget.questions.length,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _questionText(question),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).answer,
              hintText: AppLocalizations.of(context).writeCompleteAnswer,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _index == 0
                        ? null
                        : () => setState(() => _index -= 1),
                    child: Text(AppLocalizations.of(context).previous),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: widget.saving ? null : _next,
                    child: Text(
                      isLast
                          ? AppLocalizations.of(context).review
                          : AppLocalizations.of(context).next,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) => _shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          AppLocalizations.of(context).reviewAnswers,
          AppLocalizations.of(context).reviewAnswersDescription,
        ),
        const SizedBox(height: 14),
        ...widget.questions.asMap().entries.map(
          (entry) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.key + 1}. ${_questionText(entry.value)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context).edit,
                      onPressed: () => _edit(entry.key),
                      icon: const Icon(Iconsax.edit),
                    ),
                  ],
                ),
                Text(
                  widget.answers['${entry.value['id']}']!.text.trim(),
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.saving ? null : widget.onSubmit,
            child: Text(
              widget.saving
                  ? AppLocalizations.of(context).submitting
                  : AppLocalizations.of(context).submitAnswers,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.saving ? null : () => _edit(0),
            child: Text(AppLocalizations.of(context).editAnswers),
          ),
        ),
      ],
    ),
  );

  Widget _readOnly(BuildContext context) => _shell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          AppLocalizations.of(context).questionsAndAnswers,
          AppLocalizations.of(context).answersAlreadySubmitted,
        ),
        const SizedBox(height: 12),
        ...widget.questions.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}. ${_questionText(entry.value)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.answers['${entry.value['id']}']?.text
                              .trim()
                              .isNotEmpty ==
                          true
                      ? widget.answers['${entry.value['id']}']!.text.trim()
                      : AppLocalizations.of(context).noAnswer,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.label,
    required this.onTap,
  });
  final String title, description, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(color: Colors.blueGrey.shade600)),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(onPressed: onTap, child: Text(label)),
          ),
        ],
      ),
    ),
  );
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: List.generate(
      5,
      (_) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).retry),
      ),
    ],
  );
}
