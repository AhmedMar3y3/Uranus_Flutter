import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';

class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {},
          ),
          if (message.isMine && message.kind == MessageKind.text)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {},
            ),
          if (message.isMine)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {},
            ),
          if (message.kind == MessageKind.text)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}
