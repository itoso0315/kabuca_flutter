import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class DailyPackCard extends StatelessWidget {
  const DailyPackCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          children: [
            Text(
              '今日の無料パック',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'KABUCA DAILY PACK',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            const _PackVisual(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('パックを開ける'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackVisual extends StatelessWidget {
  const _PackVisual();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'KABUCAデイリーパック',
      child: Container(
        width: 156,
        height: 224,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.packGreenLight, AppColors.packGreen],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mutedGold, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25103E31),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(left: 0, right: 0, top: 10, child: _SealLine()),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: _SealLine(),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mutedGold),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.mutedGold,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'KABUCA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'DAILY PACK',
                    style: TextStyle(
                      color: AppColors.mutedGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealLine extends StatelessWidget {
  const _SealLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.mutedGold.withValues(alpha: 0.7),
    );
  }
}
