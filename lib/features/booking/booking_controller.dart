import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/booking_service.dart';
import 'booking.dart';

class BookingController extends GetxController {
  BookingController({required this.service});

  final BookingService service;
  final bookings = <Booking>[].obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isLoadingTodayDeliveryCount = false.obs;
  final isSavingBooking = false.obs;
  final todayDeliveryCount = 0.obs;
  final errorMessage = RxnString();

  Timer? _searchDebounce;
  int _requestId = 0;

  List<Booking> get filteredBookings => bookings.toList(growable: false);

  List<Booking> get todayDeliveries {
    final now = DateTime.now();
    return bookings.where((booking) => booking.isDeliveredOn(now)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _requestId++;
    searchController.dispose();
    super.onClose();
  }

  void search(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(seconds: 1), () {
      _load(search: value.trim());
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();
    searchQuery.value = '';
    _load();
  }

  Future<void> load() async {
    _searchDebounce?.cancel();
    await Future.wait([
      _load(search: searchQuery.value.trim()),
      loadTodayDeliveryCount(),
    ]);
  }

  Future<void> loadTodayDeliveryCount() async {
    if (isLoadingTodayDeliveryCount.value) return;
    isLoadingTodayDeliveryCount.value = true;
    try {
      todayDeliveryCount.value = await service.getTodayDeliveryCount();
    } on Exception {
      // Keep the last successful badge count when refreshing fails.
    } finally {
      isLoadingTodayDeliveryCount.value = false;
    }
  }

  Future<bool> createBooking(Map<String, dynamic> data) async {
    if (isSavingBooking.value) return false;
    isSavingBooking.value = true;
    try {
      await service.createBooking(data);
      await load();
      return true;
    } on Exception {
      return false;
    } finally {
      isSavingBooking.value = false;
    }
  }

  Future<void> _load({String search = ''}) async {
    final requestId = ++_requestId;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await service.getBookings(search: search);
      if (requestId != _requestId) return;
      bookings.assignAll(result);
    } on Exception {
      if (requestId != _requestId) return;
      errorMessage.value = 'មិនអាចទាញយកបញ្ជីការកក់បានទេ។';
    } finally {
      if (requestId == _requestId) isLoading.value = false;
    }
  }
}
