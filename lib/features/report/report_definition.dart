import 'package:flutter/material.dart';

class ReportDefinition {
  const ReportDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.reportPath,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final String reportPath;
}

abstract final class ReportRegistry {
  static const testReport = ReportDefinition(
    key: 'test_report',
    title: 'Test Report',
    description: 'Open this Bold report inside the application',
    icon: Icons.description_outlined,
    reportPath: '/Sales Report/test report',
  );

  static const reports = <ReportDefinition>[testReport];
}
