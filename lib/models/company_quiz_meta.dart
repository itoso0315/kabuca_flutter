import 'package:flutter/foundation.dart';

@immutable
class CompanyQuizMeta {
  const CompanyQuizMeta({
    required this.companyId,
    required this.industry,
    required this.mainBusiness,
    required this.businessTags,
    required this.quizFacts,
  });

  final String companyId;
  final String industry;
  final String mainBusiness;
  final List<String> businessTags;
  final List<String> quizFacts;
}
