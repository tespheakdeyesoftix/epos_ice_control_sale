import 'package:flutter/material.dart';

enum AppDestination {
  sale(label: 'លក់', icon: Icons.point_of_sale_outlined),
  saleSummary(label: 'សង្ខេបការលក់', icon: Icons.analytics_outlined),
  closedSales(label: 'បញ្ជីការលក់បានបិទ', icon: Icons.receipt_long_outlined),
  pendingSales(label: 'បញ្ជីការលក់ផ្អាក', icon: Icons.pending_actions_outlined),
  report(label: 'របាយការណ៍', icon: Icons.bar_chart_rounded);

  const AppDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
