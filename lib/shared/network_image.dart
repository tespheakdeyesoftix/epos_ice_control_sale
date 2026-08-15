import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The app-wide image widget for HTTP and HTTPS resources.
///
/// Files are persisted by [CachedNetworkImage] and reused across app launches.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.cacheKey,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? httpHeaders;
  final String? cacheKey;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(imageUrl);
    final isNetworkUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isNetworkUrl) {
      return SizedBox(
        width: width,
        height: height,
        child: errorWidget ?? const _ImageError(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      httpHeaders: httpHeaders,
      cacheKey: cacheKey,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => placeholder ?? const _ImageLoadingIndicator(),
      errorWidget: (_, _, _) => errorWidget ?? const _ImageError(),
    );
  }
}

class _ImageLoadingIndicator extends StatelessWidget {
  const _ImageLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
