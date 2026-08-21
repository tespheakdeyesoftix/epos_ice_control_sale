import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/sale_service.dart';
import '../closed_sales/closed_sale.dart';

class GlobalSearchController extends ChangeNotifier {
  GlobalSearchController({
    required this.saleService,
    required this.outletProvider,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final SaleService saleService;
  final String Function() outletProvider;
  final Duration debounceDuration;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  List<ClosedSale> _results = const [];
  List<ClosedSale> get results => _results;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String get query => searchController.text.trim();
  bool get isShowingRecent => query.isEmpty;

  Timer? _debounce;
  int _requestId = 0;
  bool _disposed = false;

  Future<void> loadInitial() => searchNow();

  void handleQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      searchNow();
      return;
    }
    _debounce = Timer(debounceDuration, searchNow);
  }

  void clearQuery() {
    if (searchController.text.isEmpty) return;
    searchController.clear();
    handleQueryChanged('');
    searchFocusNode.requestFocus();
  }

  Future<void> retry() => searchNow();

  Future<void> searchNow() async {
    _debounce?.cancel();
    final requestId = ++_requestId;
    final submittedQuery = query;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final page = await saleService.getClosedSales(
        outlet: outletProvider().trim(),
        search: submittedQuery,
        sortField: 'modified',
        sortAscending: false,
        limit: 10,
      );
      if (!_isCurrent(requestId)) return;
      _results = page.items;
    } on Exception {
      if (!_isCurrent(requestId)) return;
      _errorMessage = submittedQuery.isEmpty
          ? 'មិនអាចទាញយកវិក្កយបត្រលក់ថ្មីៗបានទេ។'
          : 'មិនអាចស្វែងរកវិក្កយបត្រលក់បានទេ។';
    } finally {
      if (_isCurrent(requestId)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  bool _isCurrent(int requestId) => !_disposed && requestId == _requestId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _debounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}
