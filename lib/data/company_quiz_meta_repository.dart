import '../models/company_quiz_meta.dart';
import 'card_catalog.dart';

abstract interface class CompanyQuizMetaRepository {
  Future<Map<String, CompanyQuizMeta>> load();
}

class CardCatalogCompanyQuizMetaRepository
    implements CompanyQuizMetaRepository {
  @override
  Future<Map<String, CompanyQuizMeta>> load() async => CardCatalog.quizMetadata;
}
