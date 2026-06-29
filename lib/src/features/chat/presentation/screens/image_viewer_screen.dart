import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message.dart';

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({this.message, super.key});

  final Message? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(),
      body: Stack(
        children: [
          const Center(
            child: Icon(Icons.image_outlined, color: AppTheme.cyan, size: 120),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(
              message == null
                  ? 'Image message · 8:20 PM'
                  : '${message!.senderId} · ${message!.sentAt}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
