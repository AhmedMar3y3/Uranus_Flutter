import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/app_user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _usernameController = TextEditingController(
    text: widget.user.username,
  );
  late final _fullNameController = TextEditingController(
    text: widget.user.fullName,
  );
  late final _bioController = TextEditingController(text: widget.user.bio);
  late Gender _gender = widget.user.gender == Gender.other
      ? Gender.female
      : widget.user.gender;

  String? _imagePath;
  String? _serverError;
  bool _isSaving = false;
  bool _submitted = false;

  bool get _usernameInvalid => _usernameController.text.trim().length < 3;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await picker.FilePicker.pickFiles(
      type: picker.FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (_usernameInvalid) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await AppDependencies.profileRepository.updateProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        gender: _gender,
        bio: _bioController.text.trim(),
        imagePath: _imagePath,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (mounted) {
        setState(() => _serverError = readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  UserAvatar(
                    initials: widget.user.initials,
                    imageUrl: _imagePath == null ? widget.user.imageUrl : null,
                    isOnline: widget.user.isOnline,
                    size: 112,
                  ),
                  IconButton.filled(
                    tooltip: 'Change image',
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 10),
              const Text(
                'New image selected',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.cyan),
              ),
            ],
            const SizedBox(height: 22),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassPanel(
                  padding: const EdgeInsets.all(18),
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
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<Gender>(
                          segments: const [
                            ButtonSegment(
                              value: Gender.female,
                              label: Text('Female'),
                              icon: Icon(Icons.female),
                            ),
                            ButtonSegment(
                              value: Gender.male,
                              label: Text('Male'),
                              icon: Icon(Icons.male),
                            ),
                          ],
                          selected: {_gender},
                          onSelectionChanged: (selection) {
                            setState(() => _gender = selection.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
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
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Saving' : 'Save changes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
