import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({required this.email, super.key});

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _submitted = false;
  bool _isLoading = false;

  String get _code => _controllers.map((controller) => controller.text).join();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      final chars = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].text = i < chars.length ? chars[i] : '';
      }
      final next = chars.length.clamp(0, 5);
      _focusNodes[next].requestFocus();
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_submitted) {
      setState(() {});
    }
  }

  Future<void> _verify() async {
    setState(() {
      _submitted = true;
      _isLoading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (_code == '123456') {
      Navigator.of(context).pushReplacementNamed(AppRouter.completeProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showError = _submitted && _code != '123456';

    return Scaffold(
      appBar: AppBar(),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Verify your orbit',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Code sent to ${widget.email}',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 26),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      6,
                      (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                          child: KeyboardListener(
                            focusNode: FocusNode(skipTraversal: true),
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.backspace &&
                                  _controllers[index].text.isEmpty &&
                                  index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) =>
                                  _onDigitChanged(value, index),
                              decoration: const InputDecoration(
                                counterText: '',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showError) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Use 123456 for this static preview.',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Code expires in 5 minutes',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Resend code'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verify,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(_isLoading ? 'Verifying' : 'Verify'),
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
