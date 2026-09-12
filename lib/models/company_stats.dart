import 'package:flutter/foundation.dart';

enum QuizMetric {
  revenue,
  operatingMargin,
  employees,
  equityRatio;

  String get label => switch (this) {
    QuizMetric.revenue => '売上高',
    QuizMetric.operatingMargin => '営業利益率',
    QuizMetric.employees => '従業員数',
    QuizMetric.equityRatio => '自己資本比率',
  };

  String get unit => switch (this) {
    QuizMetric.revenue => '百万円',
    QuizMetric.operatingMargin => '%',
    QuizMetric.employees => '人',
    QuizMetric.equityRatio => '%',
  };
}

@immutable
class CompanyStats {
  const CompanyStats({
    required this.companyId,
    required this.revenue,
    required this.operatingMargin,
    required this.employees,
    required this.equityRatio,
    required this.fiscalYear,
  });

  factory CompanyStats.fromJson(String companyId, Map<String, dynamic> json) {
    return CompanyStats(
      companyId: companyId,
      revenue: _number(json['revenue']),
      operatingMargin: _number(json['operatingMargin']),
      employees: _number(json['employees']),
      equityRatio: _number(json['equityRatio']),
      fiscalYear: json['fiscalYear'] as String? ?? '-',
    );
  }

  final String companyId;
  final double revenue;
  final double operatingMargin;
  final double employees;
  final double equityRatio;
  final String fiscalYear;

  double valueFor(QuizMetric metric) => switch (metric) {
    QuizMetric.revenue => revenue,
    QuizMetric.operatingMargin => operatingMargin,
    QuizMetric.employees => employees,
    QuizMetric.equityRatio => equityRatio,
  };

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    throw const FormatException('Company statistic must be numeric');
  }
}
