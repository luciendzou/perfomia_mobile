import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authService,
    required this.onAuthenticated,
  });

  final AuthService authService;
  final Future<void> Function(AuthSession) onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final session = await widget.authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) await widget.onAuthenticated(session);
    } on ApiException catch (error) {
      showAppError(error.message);
    } catch (error) {
      debugPrint('Login completion failed: $error');
      if (mounted) showAppError(AppLocalizations.of(context).retryError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandPanel(),
                    const SizedBox(height: 28),
                    Text(
                      strings.welcome,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff16345f),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.loginSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xff64748b),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.email,
                        prefixIcon: const Icon(Iconsax.sms),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? strings.validEmail
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: strings.password,
                        prefixIcon: const Icon(Iconsax.lock),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? strings.showPassword
                              : strings.hidePassword,
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? strings.shortPassword
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff2878ff),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(strings.signIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: light ? Colors.white : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Iconsax.chart_2,
          color: light ? const Color(0xff2878ff) : Colors.white,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'PERFOMIA',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: light ? Colors.white : const Color(0xff16345f),
        ),
      ),
    ],
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xff2878ff), Color(0xff20bfd7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26146bff),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const _BrandMark(light: true),
    );
  }
}
