import 'package:flutter/material.dart';

import '../state/prediction_store.dart';

class PredictionResultBell extends StatelessWidget {
  const PredictionResultBell({
    super.key,
    required this.store,
    required this.onPressed,
  });

  final PredictionStore store;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final count = store.unseenResultCount;
      return IconButton(
        key: const Key('notification-bell-button'),
        tooltip: count == 0 ? '結果確認' : '結果確認・未確認$count件',
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(
            count > 99 ? '99+' : '$count',
            key: const Key('notification-unread-badge'),
          ),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      );
    },
  );
}
