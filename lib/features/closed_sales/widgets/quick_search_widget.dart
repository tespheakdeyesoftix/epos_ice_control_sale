import 'package:flutter/material.dart';

class ClosedSaleQuickSearchWidget extends StatelessWidget {
  const ClosedSaleQuickSearchWidget({
    super.key,
    required this.searchController,
    required this.hasSearchText,
    required this.startDate,
    required this.endDate,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStartDateTap,
    required this.onClearStartDate,
    required this.onEndDateTap,
    required this.onClearEndDate,
  });

  final TextEditingController searchController;
  final bool hasSearchText;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onStartDateTap;
  final VoidCallback onClearStartDate;
  final VoidCallback onEndDateTap;
  final VoidCallback onClearEndDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 190,
          height: 42,
          child: TextField(
            key: const ValueKey('closed-sale-search-input'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ស្វែងរក',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              suffixIcon: !hasSearchText
                  ? null
                  : IconButton(
                      key: const ValueKey('clear-closed-sale-search'),
                      tooltip: 'សម្អាតការស្វែងរក',
                      onPressed: onClearSearch,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 17),
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _DateFilter(
          filterKey: const ValueKey('closed-sale-start-date-filter'),
          clearKey: const ValueKey('clear-closed-sale-start-date'),
          placeholder: 'ចាប់ពីថ្ងៃ',
          date: startDate,
          onTap: onStartDateTap,
          onClear: onClearStartDate,
        ),
        const SizedBox(width: 8),
        _DateFilter(
          filterKey: const ValueKey('closed-sale-end-date-filter'),
          clearKey: const ValueKey('clear-closed-sale-end-date'),
          placeholder: 'ដល់ថ្ងៃ',
          date: endDate,
          onTap: onEndDateTap,
          onClear: onClearEndDate,
        ),
      ],
    );
  }
}

class _DateFilter extends StatelessWidget {
  const _DateFilter({
    required this.filterKey,
    required this.clearKey,
    required this.placeholder,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final Key filterKey;
  final Key clearKey;
  final String placeholder;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 135,
      height: 42,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: filterKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 9, right: 2),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 17,
                  color: colors.primary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    date == null ? placeholder : _displayDate(date!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: date == null
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      fontSize: 11,
                      fontWeight: date == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    key: clearKey,
                    tooltip: 'លុបកាលបរិច្ឆេទ',
                    onPressed: onClear,
                    color: colors.error,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 15),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$day / $month / ${date.year}';
}
