import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../profile/domain/entities/app_user.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  String _gender = 'female';
  bool _submitted = false;
  bool _isLoading = false;
  String? _serverError;

  bool get _usernameInvalid => _usernameController.text.trim().length < 3;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (_usernameInvalid) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AppDependencies.profileRepository.completeProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        gender: _gender == 'male' ? Gender.male : Gender.female,
        bio: _bioController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRouter.shell);
    } catch (error) {
      setState(() => _serverError = readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete profile')),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const AppLogo(size: 104),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassPanel(
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    onChanged: (_) => setState(() => _serverError = null),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      errorText: _submitted && _usernameInvalid
                          ? 'Username must be at least 3 characters'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'female',
                        label: Text('Female'),
                        icon: Icon(Icons.female),
                      ),
                      ButtonSegment(
                        value: 'male',
                        label: Text('Male'),
                        icon: Icon(Icons.male),
                      ),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (selection) {
                      setState(() => _gender = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Optional',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  if (_serverError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _serverError!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _complete,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isLoading ? 'Saving' : 'Complete profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Profile image preview is static for now; upload wiring can plug into the repository layer later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
