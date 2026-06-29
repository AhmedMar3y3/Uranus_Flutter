import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _usernameController = TextEditingController();
  String _gender = 'female';
  bool _submitted = false;

  bool get _usernameTaken =>
      _usernameController.text.trim().toLowerCase() == 'uranus';

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _complete() {
    setState(() => _submitted = true);
    if (_usernameTaken) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.shell);
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
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      errorText: _submitted && _usernameTaken
                          ? 'Username already taken'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
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
                  const TextField(
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Optional',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _complete,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete profile'),
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
