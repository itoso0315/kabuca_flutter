import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'kabu_currency.dart';

class DailyPackCard extends StatelessWidget {
  const DailyPackCard({
    super.key,
    required this.onOpen,
    required this.packCount,
    this.onOpenWithKabu,
    this.kabuBalance = 0,
    this.kabuCost = 100,
    this.packName = 'START PACK',
    this.isPremium = false,
    this.isLocked = false,
    this.isSuperPremium = false,
  });

  final VoidCallback? onOpen;
  final int packCount;
  final VoidCallback? onOpenWithKabu;
  final int kabuBalance;
  final int kabuCost;

  final String packName;
  final bool isPremium;
  final bool isLocked;
  final bool isSuperPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasFreePack = packCount > 0 && !isLocked;
    final canOpenWithKabu =
        !hasFreePack && kabuBalance >= kabuCost && onOpenWithKabu != null;
    final kabuShortage = kabuCost - kabuBalance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          children: [
            Text(
              packName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (isLocked) ...[
              const SizedBox(height: 5),
              Text(
                '所持カード100枚で解放',
                key: const Key('super-premium-pack-lock-guidance'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ] else if (isSuperPremium) ...[
              const SizedBox(height: 5),
              Text(
                'R 20% / SR 55% / UR 25%',
                key: const Key('super-premium-pack-rarity-guidance'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (isPremium) ...[
              const SizedBox(height: 5),
              Text(
                'SR 42% / UR 8%  (START PACK: SR 19% / UR 3%)',
                key: const Key('premium-pack-rarity-guidance'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 22),
            _CardStackVisual(
              isPremium: isPremium,
              isSuperPremium: isSuperPremium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: Key(
                  isLocked
                      ? 'super-premium-locked-button'
                      : packName == 'SUPER PREMIUM PACK'
                      ? 'open-super-premium-pack-button'
                      : hasFreePack
                      ? 'open-free-pack-button'
                      : 'open-pack-with-kabu-button',
                ),
                onPressed: hasFreePack
                    ? onOpen
                    : canOpenWithKabu
                    ? onOpenWithKabu
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLocked
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded),
                          SizedBox(width: 8),
                          Text('ロック中'),
                        ],
                      )
                    : hasFreePack
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_rounded),
                          SizedBox(width: 8),
                          Text('パックを開ける'),
                        ],
                      )
                    : KabuCurrencyText(text: '$kabuCost KABUで開ける'),
              ),
            ),
            if (!hasFreePack) ...[
              const SizedBox(height: 12),
              kabuShortage > 0
                  ? KabuCurrencyText(
                      key: const Key('pack-kabu-guidance'),
                      text: 'あと$kabuShortage KABUで開けられます',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Text(
                      '3枚入り',
                      key: const Key('pack-kabu-guidance'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardStackVisual extends StatelessWidget {
  const _CardStackVisual({
    required this.isPremium,
    required this.isSuperPremium,
  });

  final bool isPremium;
  final bool isSuperPremium;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: isSuperPremium
          ? 'KABUCA SUPER PREMIUM PACKのカード3枚'
          : isPremium
          ? 'KABUCA PREMIUM PACKのカード3枚'
          : 'KABUCA START PACKのカード3枚',
      child: SizedBox(
        width: 230,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-54, 8),
              child: Transform.rotate(
                angle: -0.11,
                child: _MiniCardBack(
                  width: 116,
                  height: 166,
                  opacity: 0.88,
                  isPremium: isPremium,
                  isSuperPremium: isSuperPremium,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(54, 8),
              child: Transform.rotate(
                angle: 0.11,
                child: _MiniCardBack(
                  width: 116,
                  height: 166,
                  opacity: 0.88,
                  isPremium: isPremium,
                  isSuperPremium: isSuperPremium,
                ),
              ),
            ),
            _MiniCardBack(
              width: 128,
              height: 182,
              opacity: 1,
              isPremium: isPremium,
              isSuperPremium: isSuperPremium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCardBack extends StatelessWidget {
  const _MiniCardBack({
    required this.width,
    required this.height,
    required this.opacity,
    required this.isPremium,
    required this.isSuperPremium,
  });

  final double width;
  final double height;
  final double opacity;

  final bool isPremium;
  final bool isSuperPremium;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSuperPremium
                ? const [
                    Color(0xFFFFE7A3),
                    Color(0xFFD19A32),
                    Color(0xFF9A6818),
                  ]
                : isPremium
                ? const [
                    Color(0xFF171A19),
                    Color(0xFF0B0F0E),
                    Color(0xFF030504),
                  ]
                : const [Color(0xFF174B3E), Color(0xFF0D332B)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.mutedGold.withValues(
              alpha: isPremium || isSuperPremium ? 1 : 0.8,
            ),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPremium || isSuperPremium
                  ? const Color(0x3D000000)
                  : const Color(0x26103E31),
              blurRadius: isPremium || isSuperPremium ? 22 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isPremium || isSuperPremium)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.03),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.025),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.mutedGold.withValues(
                        alpha: isPremium || isSuperPremium ? 0.7 : 0.35,
                      ),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPremium || isSuperPremium
                            ? const Color(0xFFFFE6A3)
                            : const Color(0xFFFFD879),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: isPremium || isSuperPremium
                            ? Color(0xFFFFE6A3)
                            : Color(0xFFFFD879),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'KABUCA',
                    style: TextStyle(
                      color: isSuperPremium
                          ? Color(0xFFFFF3C4)
                          : isPremium
                          ? Color(0xFFFFEBC2)
                          : Color(0xFFFFE2A0),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.8,
                    ),
                  ),
                ],
              ),
            ),
            if (isPremium || isSuperPremium)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Text(
                  isSuperPremium ? 'SUPER PREMIUM' : 'PREMIUM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD879),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
