import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AttachmentPreviewScreen extends StatelessWidget {
  const AttachmentPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 360,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 72, color: AppTheme.cyan),
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
    );
  }
}
