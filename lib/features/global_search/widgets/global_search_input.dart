import 'package:flutter/material.dart';

class GlobalSearchInput extends StatelessWidget {
  const GlobalSearchInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('global-search-input'),
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ស្វែងរកលេខវិក្កយបត្រ អតិថិជន ឬលេខទូរស័ព្ទ',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'F3',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : IconButton(
                  key: const ValueKey('clear-global-search'),
                  tooltip: 'សម្អាត',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}
