import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/sale_service.dart';
import '../closed_sales/closed_sale.dart';

class GlobalSearchController extends ChangeNotifier {
  GlobalSearchController({
    required this.saleService,
    required this.outletProvider,
    this.debounceDuration = const Duration(seconds: 1),
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
  bool _hasLoaded = false;
  String? _loadedOutlet;

  Future<void> loadInitial() => searchNow();

  Future<void> ensureLoaded() {
    final outlet = outletProvider().trim();
    if (_hasLoaded && _loadedOutlet == outlet) return Future<void>.value();
    if (_loadedOutlet != null && _loadedOutlet != outlet) {
      searchController.clear();
      _results = const [];
      _errorMessage = null;
    }
    return searchNow();
  }

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

  void discardSearchWithoutResults() {
    if (query.isEmpty || _results.isNotEmpty) return;
    _debounce?.cancel();
    _requestId++;
    searchController.clear();
    _results = const [];
    _errorMessage = null;
    _isLoading = false;
    _hasLoaded = false;
    _notify();
  }

  Future<void> searchNow() async {
    _debounce?.cancel();
    final requestId = ++_requestId;
    final submittedQuery = query;
    final submittedOutlet = outletProvider().trim();
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final page = await saleService.getClosedSales(
        outlet: submittedOutlet,
        search: submittedQuery,
        sortField: 'modified',
        sortAscending: false,
        limit: submittedQuery.isEmpty ? 10 : 20,
      );
      if (!_isCurrent(requestId)) return;
      _results = page.items;
      _loadedOutlet = submittedOutlet;
      _hasLoaded = true;
    } on Exception {
      if (!_isCurrent(requestId)) return;
      _loadedOutlet = submittedOutlet;
      _hasLoaded = true;
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
