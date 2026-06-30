import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message.dart';

class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({
    required this.message,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Message message;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (message.kind == MessageKind.text && onCopy != null)
        ListTile(
          leading: const Icon(Icons.copy),
          title: const Text('Copy text'),
          onTap: onCopy,
        ),
      if (message.isMine && message.kind == MessageKind.text && onEdit != null)
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit'),
          onTap: onEdit,
        ),
      if (message.isMine && onDelete != null)
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Delete'),
          onTap: onDelete,
        ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.deepNavy,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Wrap(
            children: actions.isEmpty
                ? const [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('No actions available'),
                    ),
                  ]
                : actions,
          ),
        ),
      ),
    );
  }
}
