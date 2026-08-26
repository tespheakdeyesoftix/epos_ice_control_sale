import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'booking.dart';
import 'booking_controller.dart';
import 'widgets/booking_card_widget.dart';
import 'widgets/booking_detail_dialog_widget.dart';
import 'widgets/search_input_widget.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  void _openDetail(
    BuildContext context,
    Booking booking,
    BookingController controller,
  ) {
    showBookingDetailDialog(
      context,
      booking: booking,
      service: controller.service,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (!Get.isRegistered<BookingController>()) {
      return Scaffold(
        backgroundColor: colors.surfaceContainerLow,
        body: const Center(child: Text('មិនអាចបើកមុខងារការកក់បានទេ។')),
      );
    }
    final controller = Get.find<BookingController>();
    return Scaffold(
      key: const ValueKey('booking-list-screen'),
      backgroundColor: colors.surfaceContainerLow,
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          if (controller.isLoading.value && controller.bookings.isEmpty) {
            return const _ScrollableMessage(child: CircularProgressIndicator());
          }
          final error = controller.errorMessage.value;
          if (error != null && controller.bookings.isEmpty) {
            return _ScrollableMessage(
              child: _ErrorState(message: error, onRetry: controller.load),
            );
          }

          final today = controller.todayDeliveries;
          final all = controller.filteredBookings;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _PageHeader(
                  total: all.length,
                  totalUnfiltered: controller.bookings.length,
                  searchController: controller.searchController,
                  searchQuery: controller.searchQuery.value,
                  onSearchChanged: controller.search,
                  onClearSearch: controller.clearSearch,
                  isLoading: controller.isLoading.value,
                  onRefresh: controller.load,
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.local_shipping_rounded,
                  title: 'ការដឹកជញ្ជូនថ្ងៃនេះ',
                  count: today.length,
                  highlighted: true,
                ),
              ),
              SliverToBoxAdapter(
                child: _TodaySection(
                  bookings: today,
                  onTap: (booking) => _openDetail(context, booking, controller),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.event_note_rounded,
                  title: 'បញ្ជីការកក់ទាំងអស់',
                  count: all.length,
                ),
              ),
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.event_busy_outlined,
                    message: controller.searchQuery.value.isEmpty
                        ? 'មិនមានការកក់នៅឡើយទេ'
                        : 'រកមិនឃើញការកក់ដែលត្រូវគ្នាទេ',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = width >= 1200
                          ? 3
                          : width >= 720
                          ? 2
                          : 1;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 222,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => BookingCardWidget(
                            booking: all[index],
                            isToday: all[index].isDeliveredOn(DateTime.now()),
                            onTap: () =>
                                _openDetail(context, all[index], controller),
                          ),
                          childCount: all.length,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.total,
    required this.totalUnfiltered,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.isLoading,
    required this.onRefresh,
  });

  final int total;
  final int totalUnfiltered;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ការកក់',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                searchQuery.isEmpty
                    ? 'ការកក់សរុប $totalUnfiltered'
                    : 'រកឃើញ $total ក្នុងចំណោម $totalUnfiltered',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
    final search = SearchInputWidget(
      controller: searchController,
      query: searchQuery,
      onChanged: onSearchChanged,
      onClear: onClearSearch,
    );
    final refresh = IconButton.filledTonal(
      key: const ValueKey('refresh-bookings'),
      tooltip: 'ផ្ទុកឡើងវិញ',
      onPressed: isLoading ? null : onRefresh,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
      color: colors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    refresh,
                  ],
                ),
                const SizedBox(height: 14),
                search,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              SizedBox(width: 390, child: search),
              const SizedBox(width: 10),
              refresh,
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: highlighted ? colors.primary : null),
          const SizedBox(width: 9),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: highlighted
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection({required this.bookings, required this.onTap});

  final List<Booking> bookings;
  final ValueChanged<Booking> onTap;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 116,
          child: _EmptyState(
            icon: Icons.local_shipping_outlined,
            message: 'ថ្ងៃនេះមិនមានការដឹកជញ្ជូនទេ',
          ),
        ),
      );
    }
    return SizedBox(
      height: 222,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => SizedBox(
          width: 360,
          child: BookingCardWidget(
            booking: bookings[index],
            isToday: true,
            onTap: () => onTap(bookings[index]),
          ),
        ),
      ),
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: constraints.maxHeight,
        child: Center(child: child),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.cloud_off_rounded, size: 44),
      const SizedBox(height: 10),
      Text(message),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('ព្យាយាមម្តងទៀត'),
      ),
    ],
  );
}
