import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/onboarding_storage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onCompleted});

  final Future<void> Function() onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final _storage = OnboardingStorage();
  int _currentPage = 0;
  bool _saving = false;

  List<_OnboardingStep> _steps(AppLocalizations strings) => [
    _OnboardingStep(
      icon: Iconsax.element_4,
      title: strings.onboardingWorkspace,
      description: strings.onboardingWorkspaceDescription,
      imageAsset: null,
    ),
    _OnboardingStep(
      icon: Iconsax.task_square,
      title: strings.onboardingProjects,
      description: strings.onboardingProjectsDescription,
      imageAsset: null,
    ),
    _OnboardingStep(
      icon: Iconsax.notification,
      title: strings.onboardingNotifications,
      description: strings.onboardingNotificationsDescription,
      imageAsset: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _storage.markCompleted();
    await widget.onCompleted();
  }

  void _next() {
    if (_currentPage == 2) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final steps = _steps(strings);
    final isLastPage = _currentPage == steps.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xfff7fbff),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  _LogoMark(color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'PERFOMIA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Color(0xff2878ff),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    child: Text(strings.skip),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _StepView(step: steps[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? theme.colorScheme.primary
                          : const Color(0xffdce5f2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _next,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastPage ? strings.start : strings.next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ImageSlot(step: step, color: theme.colorScheme.primary),
          const SizedBox(height: 30),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xff64748b),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({required this.step, required this.color});

  final _OnboardingStep step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: step.imageAsset == null
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffe9f3ff), Color(0xfff2fdff)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(step.icon, size: 54, color: color),
                  ),
                ),
              )
            : Image.asset(step.imageAsset!, fit: BoxFit.cover),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Iconsax.chart_2, color: Colors.white, size: 19),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    this.imageAsset,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? imageAsset;
}
