import 'package:flutter/material.dart';

import 'state_placeholder.dart';

class RefreshablePlaceholder extends StatelessWidget {
  const RefreshablePlaceholder({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRefresh,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * .18),
          StatePlaceholder(icon: icon, title: title, body: body),
        ],
      ),
    );
  }
}
