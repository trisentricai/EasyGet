import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/catalog_models.dart';

/// Trendy category tile (web-style): image avatar on top, name below.
/// Shared by the Home grid and the Search shortcuts rail so categories are
/// recognised by picture, not just by label.
///
/// Backend images may be absolute URLs or `/media/…` paths (admin uploads);
/// [AppConfig.mediaUrl] absolutizes the latter.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    this.onTap,
    this.size = 64,
  });

  final Category category;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('category-tile-${category.slug}'),
      borderRadius: BorderRadius.circular(AppRadii.image),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(image: category.image, size: size),
          const SizedBox(height: 4),
          SizedBox(
            width: size + 16,
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption(
                  Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big list row: 72px image left, name (+ optional count) middle, chevron
/// right. Used by the Search category browser.
class CategoryListTile extends StatelessWidget {
  const CategoryListTile({
    super.key,
    required this.category,
    this.onTap,
  });

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('category-tile-${category.slug}'),
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border:
              Border.all(color: Theme.of(context).freshColors.faint),
        ),
        child: Row(
          children: [
            _Avatar(image: category.image, size: 72),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.productName(scheme.onSurface,
                        size: 15),
                  ),
                  if (category.productCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${category.productCount} products',
                      style: AppTypography.tabularSmall(
                          scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.image, required this.size});

  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).freshColors;
    final url = AppConfig.mediaUrl(image);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.sunken,
        borderRadius: BorderRadius.circular(AppRadii.image),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(Icons.grid_view_outlined,
              color: colors.faint, size: size * 0.4)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(
                Icons.grid_view_outlined,
                color: colors.faint,
                size: size * 0.4,
              ),
            ),
    );
  }
}