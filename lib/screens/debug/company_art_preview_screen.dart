import 'package:flutter/material.dart';

import '../../data/company_master.dart';
import '../../models/company_card.dart';
import '../../theme/company_artwork_registry.dart';
import '../../widgets/company_card_artwork.dart';

class CompanyArtPreviewScreen extends StatefulWidget {
  const CompanyArtPreviewScreen({
    super.key,
    this.availableCompanies,
    this.allCompanies = CompanyMaster.companies,
  });

  final Future<List<CompanyMasterEntry>>? availableCompanies;
  final List<CompanyMasterEntry> allCompanies;

  @override
  State<CompanyArtPreviewScreen> createState() =>
      _CompanyArtPreviewScreenState();
}

class _CompanyArtPreviewScreenState extends State<CompanyArtPreviewScreen> {
  late final Future<List<CompanyMasterEntry>> _availableCompanies;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _availableCompanies =
        widget.availableCompanies ??
        CompanyArtworkRegistry.availableCompanies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('企業アート確認', key: Key('company-art-preview-title')),
      ),
      body: FutureBuilder<List<CompanyMasterEntry>>(
        future: _availableCompanies,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final available = snapshot.data!;
          final companies = _showFallback ? widget.allCompanies : available;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '画像あり ${available.length}社 / '
                        'CompanyMaster ${widget.allCompanies.length}社',
                        key: const Key('company-art-count'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Text('fallbackも表示'),
                    Switch(
                      key: const Key('show-fallback-switch'),
                      value: _showFallback,
                      onChanged: (value) =>
                          setState(() => _showFallback = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  key: const Key('company-art-grid'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.69,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return InkWell(
                      key: Key('company-art-preview-${company.companyId}'),
                      onTap: () => _openDetail(company),
                      borderRadius: BorderRadius.circular(16),
                      child: CompanyCardArtwork(
                        card: _previewCard(company),
                        compact: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(CompanyMasterEntry company) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _CompanyArtDetailScreen(company: company),
      ),
    );
  }
}

class _CompanyArtDetailScreen extends StatelessWidget {
  const _CompanyArtDetailScreen({required this.company});

  final CompanyMasterEntry company;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(company.companyName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CompanyCardArtwork(
              card: _previewCard(company),
              width: 294,
              height: 412,
            ),
          ),
          const SizedBox(height: 24),
          SelectableText(
            'companyName: ${company.companyName}\n'
            'companyId: ${company.companyId}\n'
            'ticker: ${company.ticker}\n'
            'industry: ${company.industry}\n'
            'artworkPath: ${company.artworkPath}',
            key: const Key('company-art-detail-metadata'),
          ),
        ],
      ),
    );
  }
}

CompanyCard _previewCard(CompanyMasterEntry company) => CompanyCard(
  id: '${company.companyId}_art_preview',
  companyId: company.companyId,
  companyName: company.companyName,
  ticker: company.ticker,
  industry: company.industry,
  rarity: CardRarity.n,
  title: '企業アート確認',
  description: '',
);
