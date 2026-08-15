import 'package:flutter/material.dart';

import '../../../shared/network_image.dart';
import '../../../utils/helpers.dart';
import '../product.dart';

class ProductCardWidget extends StatelessWidget {
  const ProductCardWidget({
    super.key,
    required this.product,
    required this.imageUri,
    required this.onTap,
  });

  final Product product;
  final Uri? imageUri;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productColor = colorFromHex(product.color, fallback: colors.primary);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: productColor.withValues(alpha: 0.12),
                  child: imageUri == null
                      ? Icon(
                          Icons.ac_unit_rounded,
                          color: productColor,
                          size: 42,
                        )
                      : AppNetworkImage(
                          imageUrl: imageUri.toString(),
                          fit: BoxFit.cover,
                          memCacheWidth: 480,
                          maxWidthDiskCache: 720,
                          errorWidget: Icon(
                            Icons.ac_unit_rounded,
                            color: productColor,
                            size: 42,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatMoney(product.price)} រៀល / ${product.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: productColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
