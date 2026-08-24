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

  factory ReportDefinition.fromJson(Map<String, dynamic> json) {
    final reportPath = json['report_url']?.toString().trim() ?? '';
    final pathName = reportPath.split('/').last.trim().toLowerCase();
    return ReportDefinition(
      key: pathName.replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      title: json['report_title']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
      icon: Icons.description_outlined,
      reportPath: reportPath,
    );
  }
}
