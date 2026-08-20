import 'package:flutter/material.dart';

class ReportDefinition {
  const ReportDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    this.includeOutlet = false,
    this.includeReportDate = false,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool includeOutlet;
  final bool includeReportDate;
}

abstract final class ReportRegistry {
  static const financialAnalysis = ReportDefinition(
    key: 'financial_analysis',
    title: 'Financial Analysis',
    description: 'Bold Reports embedded-viewer proof of concept',
    icon: Icons.analytics_outlined,
  );

  static const reports = <ReportDefinition>[financialAnalysis];
}
