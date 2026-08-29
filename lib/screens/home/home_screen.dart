import 'package:flutter/material.dart';

import '../../widgets/daily_pack_card.dart';
import '../../widgets/home_stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('KABUCA', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '今日も、1パック。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              DailyPackCard(onOpen: () => _showComingSoon(context)),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: HomeStatCard(label: '所持カード', value: '0枚'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: HomeStatCard(label: '図鑑コンプリート率', value: '0%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('パック開封はTask003で実装予定です')),
      );
  }
}
