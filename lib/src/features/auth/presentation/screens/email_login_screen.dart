import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  bool get _isValidEmail {
    final value = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _submitted = true);
    if (!_isValidEmail) {
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(AppRouter.otp);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final showError = _submitted && !_isValidEmail;

    return Scaffold(
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            const Center(child: AppLogo(size: 112)),
            const SizedBox(height: 28),
            Text(
              'Uranus',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter with email OTP and keep your social orbit private.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            GlassPanel(
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_submitted) {
                        setState(() {});
                      }
                    },
                    onSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'noura@uranus.app',
                      prefixIcon: const Icon(Icons.alternate_email),
                      errorText: showError
                          ? 'Please enter a valid email address.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _continue,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_isLoading ? 'Sending code' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
