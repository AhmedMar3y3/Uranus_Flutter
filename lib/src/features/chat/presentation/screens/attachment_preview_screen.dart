import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/space_background.dart';

class AttachmentPreviewScreen extends StatelessWidget {
  const AttachmentPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: SpaceBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            GlassPanel(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 360,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: .56),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 72,
                      color: AppTheme.cyan,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(hintText: 'Add a caption'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.close),
              label: const Text('Remove attachment'),
            ),
          ],
        ),
      ),
    );
  }
}
