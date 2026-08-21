import 'package:flutter/material.dart';

import '../../../features/sell/sale.dart';
import '../../../shared/network_image.dart';
import '../../../utils/helpers.dart';
import 'customer_credit_warning_card.dart';
import 'split_bill_parent_banner_widget.dart';

class SaleInvoiceHeaderCard extends StatelessWidget {
  const SaleInvoiceHeaderCard({
    super.key,
    required this.sale,
    required this.rawDocument,
    required this.imageBaseUri,
    required this.onBack,
    required this.onRefresh,
    required this.onReprint,
    required this.onEdit,
    required this.onDelete,
    required this.onPreview,
    required this.onPaymentHistory,
    required this.onViewSplitBills,
    required this.onEditReferenceNumber,
    required this.onOpenParentBill,
    required this.isPrinting,
    required this.isRefreshing,
    required this.currencySymbol,
  });

  final Sale sale;
  final Map<String, dynamic> rawDocument;
  final Uri? imageBaseUri;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onReprint;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPreview;
  final VoidCallback? onPaymentHistory;
  final VoidCallback? onViewSplitBills;
  final VoidCallback? onEditReferenceNumber;
  final VoidCallback? onOpenParentBill;
  final bool isPrinting;
  final bool isRefreshing;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMasterInvoice = sale.canSplitBill && sale.totalSplitBill > 0;
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const [Color(0xFF173A58), Color(0xFF1D3151)]
        : const [Color(0xFFE8F6F3), Color(0xFFEEF4FF)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: background),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: .16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  key: const ValueKey('sale-detail-back'),
                  tooltip: 'ត្រឡប់ក្រោយ',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'វិក្កយបត្រ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 9,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            sale.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (sale.parentBillNumber.trim().isNotEmpty &&
                              onOpenParentBill != null)
                            SplitBillParentBannerWidget(
                              parentBillNumber: sale.parentBillNumber,
                              onOpenParent: onOpenParentBill!,
                            ),
                          if (isMasterInvoice) const _MasterInvoicePill(),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (CustomerCreditWarningCard.shouldShow(sale)) ...[
                      CustomerCreditWarningCard(
                        sale: sale,
                        currencySymbol: currencySymbol,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _StatusPill(
                      label: sale.status.isEmpty
                          ? sale.saleStatus
                          : sale.status,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: isRefreshing
                          ? Icons.hourglass_top_rounded
                          : Icons.refresh_rounded,
                      label: 'ផ្ទុកឡើងវិញ',
                      onPressed: isRefreshing ? null : onRefresh,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final customer = _CustomerPanel(
                  sale: sale,
                  imageBaseUri: imageBaseUri,
                );
                final invoice = _InvoicePanel(
                  sale: sale,
                  rawDocument: rawDocument,
                  onEditReferenceNumber: onEditReferenceNumber,
                );
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [customer, const SizedBox(height: 12), invoice],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: customer),
                    const SizedBox(width: 12),
                    Expanded(child: invoice),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _ReprintCopiesButton(
                  isPrinting: isPrinting,
                  onSelected: onReprint,
                ),
                if (isMasterInvoice)
                  _ActionButton(
                    icon: Icons.account_tree_outlined,
                    label: 'មើលបុងបំបែក',
                    badgeCount: sale.totalSplitBill,
                    onPressed: onViewSplitBills,
                    standout: true,
                  ),
                _ActionButton(
                  icon: Icons.edit_note_rounded,
                  label: 'កែសម្រួលការកុម្ម៉ង់',
                  onPressed: onEdit,
                ),
                _ActionButton(
                  icon: Icons.preview_rounded,
                  label: 'មើលមុនពេលបោះពុម្ព',
                  onPressed: onPreview,
                ),
                _ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'មើលប្រវត្តិការទូទាត់',
                  onPressed: onPaymentHistory,
                ),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'លុបការកុម្ម៉ង់',
                  onPressed: onDelete,
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReprintCopiesButton extends StatelessWidget {
  const _ReprintCopiesButton({
    required this.isPrinting,
    required this.onSelected,
  });

  final bool isPrinting;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      key: const ValueKey('reprint-receipt-copies'),
      enabled: !isPrinting && onSelected != null,
      tooltip: 'ជ្រើសរើសចំនួនច្បាប់ចម្លង',
      onSelected: onSelected,
      itemBuilder: (context) => List.generate(3, (index) {
        final copies = index + 1;
        return PopupMenuItem<int>(
          value: copies,
          child: Row(
            children: [
              Icon(
                copies == 1
                    ? Icons.looks_one_outlined
                    : Icons.copy_all_outlined,
                size: 19,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Text('$copies ច្បាប់'),
            ],
          ),
        );
      }),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isPrinting || onSelected == null
              ? colors.onSurface.withValues(alpha: .12)
              : colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPrinting ? Icons.hourglass_top_rounded : Icons.print_rounded,
              size: 19,
              color: isPrinting || onSelected == null
                  ? colors.onSurface.withValues(alpha: .38)
                  : colors.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'បោះពុម្ពវិក្កយបត្រឡើងវិញ',
              style: TextStyle(
                color: isPrinting || onSelected == null
                    ? colors.onSurface.withValues(alpha: .38)
                    : colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: isPrinting || onSelected == null
                  ? colors.onSurface.withValues(alpha: .38)
                  : colors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicePanel extends StatelessWidget {
  const _InvoicePanel({
    required this.sale,
    required this.rawDocument,
    required this.onEditReferenceNumber,
  });

  final Sale sale;
  final Map<String, dynamic> rawDocument;
  final VoidCallback? onEditReferenceNumber;

  @override
  Widget build(BuildContext context) => _InfoPanel(
    icon: Icons.receipt_long_rounded,
    title: 'ព័ត៌មានវិក្កយបត្រ',
    children: [
      _InfoLine(label: 'កាលបរិច្ឆេទ', value: formatDate(sale.postingDate)),
      _InfoLine(
        label: 'កន្លែងលក់',
        value: sale.outlet.isEmpty ? '-' : sale.outlet,
      ),
      _InfoLine(
        label: 'ម៉ាស៊ីនលក់',
        value: sale.station.isEmpty ? '-' : sale.station,
      ),
      _InfoLine(
        label: 'អ្នកលក់',
        value: sale.seller.isEmpty
            ? textValue(rawDocument['owner'])
            : sale.seller,
      ),
      _InfoLine(
        label: 'លេខយោង',
        value: sale.referenceNumber.isEmpty
            ? 'កែប្រែលេខយោង'
            : sale.referenceNumber,
        onTap: onEditReferenceNumber,
        editable: true,
      ),
    ],
  );
}

class _CustomerPanel extends StatelessWidget {
  const _CustomerPanel({required this.sale, required this.imageBaseUri});

  final Sale sale;
  final Uri? imageBaseUri;

  @override
  Widget build(BuildContext context) => _InfoPanel(
    icon: Icons.person_outline_rounded,
    title: 'ព័ត៌មានអតិថិជន',
    trailing: _CustomerAvatar(
      imagePath: sale.customerPhoto,
      imageBaseUri: imageBaseUri,
    ),
    children: [
      _InfoLine(label: 'ឈ្មោះ', value: _customerNameWithCode(sale)),
      _InfoLine(
        label: 'ទូរស័ព្ទ',
        value: sale.phoneNumber.isEmpty ? '-' : sale.phoneNumber,
      ),
      _InfoLine(
        label: 'ក្រុមអតិថិជន',
        value: sale.customerGroup.isEmpty ? '-' : sale.customerGroup,
      ),
      _InfoLine(
        label: 'អ្នកបើកបរ',
        value: sale.driverName.isEmpty ? '-' : sale.driverName,
      ),
      if (sale.plateNumber.isNotEmpty)
        _InfoLine(label: 'ផ្លាកលេខ', value: sale.plateNumber),
    ],
  );
}

String _customerNameWithCode(Sale sale) {
  final name = sale.customerName.trim();
  final code = sale.customer.trim();
  if (name.isEmpty) return code.isEmpty ? '-' : code;
  if (code.isEmpty || code == name) return name;
  return '$name ($code)';
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ...children,
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .8)),
      ),
      child: trailing == null
          ? content
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 104),
                  child: content,
                ),
                Positioned(top: 0, right: 0, child: trailing!),
              ],
            ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.imagePath, required this.imageBaseUri});

  final String imagePath;
  final Uri? imageBaseUri;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photo = imagePath.trim();
    final parsed = Uri.tryParse(photo);
    final imageUrl = photo.isEmpty
        ? null
        : parsed != null &&
              (parsed.scheme == 'http' || parsed.scheme == 'https')
        ? parsed.toString()
        : imageBaseUri?.resolve(photo).toString();
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person_rounded, size: 38, color: colors.primary),
    );
    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: .24),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl == null
            ? fallback
            : AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 172,
                memCacheHeight: 172,
                placeholder: ColoredBox(color: colors.surfaceContainerHighest),
                errorWidget: fallback,
              ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.onTap,
    this.editable = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(child: _buildValue(context, colors)),
        ],
      ),
    );
  }

  Widget _buildValue(BuildContext context, ColorScheme colors) {
    final text = Text(
      value.isEmpty ? '-' : value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: editable ? colors.primary : colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
    if (!editable) return text;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 5),
            Icon(Icons.edit_outlined, size: 15, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (label.trim().toLowerCase()) {
      'paid' => const Color(0xFF168A45),
      'unpaid' => colors.error,
      'partially paid' => const Color(0xFFD97706),
      _ => colors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        _statusLabel(label),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MasterInvoicePill extends StatelessWidget {
  const _MasterInvoicePill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.tertiary.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.tertiary.withValues(alpha: .3)),
      ),
      child: Text(
        'វិក្កយបត្រមេ',
        style: TextStyle(
          color: colors.tertiary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _statusLabel(String value) => switch (value.trim().toLowerCase()) {
  'paid' => 'បានទូទាត់',
  'unpaid' => 'មិនទាន់ទូទាត់',
  'partially paid' => 'បានទូទាត់ខ្លះ',
  'closed' => 'បានបិទ',
  'draft' => 'ព្រាង',
  'deleted' => 'បានលុប',
  '' => 'បានបិទ',
  _ => value,
};

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.badgeCount,
    this.standout = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final int? badgeCount;
  final bool standout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const standoutColor = Color(0xFF7C3AED);
    final baseStyle = OutlinedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        style: destructive
            ? baseStyle.copyWith(
                foregroundColor: WidgetStatePropertyAll(colors.error),
                side: WidgetStatePropertyAll(
                  BorderSide(color: colors.error.withValues(alpha: .45)),
                ),
              )
            : standout
            ? baseStyle.copyWith(
                backgroundColor: const WidgetStatePropertyAll(standoutColor),
                foregroundColor: const WidgetStatePropertyAll(Colors.white),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: standoutColor),
                ),
              )
            : baseStyle,
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (badgeCount != null) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: standout
                      ? Colors.white.withValues(alpha: .2)
                      : colors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
