import 'package:flutter/material.dart';

import '../../widgets/daily_pack_card.dart';
import '../../widgets/home_stat_card.dart';
import '../../models/company_card.dart';
import '../../services/card_pack_service.dart';
import '../pack/pack_opening_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialPackCount = 3,
    this.initialCardCount = 0,
    this.cardPackService,
  });

  final int initialPackCount;
  final int initialCardCount;
  final CardPackService? cardPackService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _packCount;
  late int _ownedCardCount;
  late final CardPackService _cardPackService;

  @override
  void initState() {
    super.initState();
    _packCount = widget.initialPackCount;
    _ownedCardCount = widget.initialCardCount;
    _cardPackService = widget.cardPackService ?? CardPackService();
  }

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
              Text('集めよう、日本の企業。', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              DailyPackCard(
                packCount: _packCount,
                onOpen: _packCount > 0 ? () => _openPack(context) : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: HomeStatCard(
                      label: '所持カード',
                      value: '$_ownedCardCount枚',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HomeStatCard(
                      label: '図鑑コンプリート率',
                      value: '$_ownedCardCount%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPack(BuildContext context) async {
    final cards = await Navigator.of(context).push<List<CompanyCard>>(
      PackOpeningRoute(
        cards: _cardPackService.openPack(),
        onPackOpened: _consumePack,
      ),
    );
    if (cards == null || !mounted) return;
    setState(() => _ownedCardCount += cards.length);
  }

  void _consumePack() {
    if (!mounted || _packCount <= 0) return;
    setState(() => _packCount--);
  }
}
