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

class _Avatar extends StatelessWidget {  const _Avatar({required this.image, required this.size});

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

/// Big 2-column image card: photo (or sunken fallback) with the name over a
/// scrim and an optional count pill. The Search browser's trendy face —
/// deliberately different from the home track and the address rows.
class CategoryGridCard extends StatelessWidget {
  const CategoryGridCard({
    super.key,
    required this.category,
    this.onTap,
  });

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final url = AppConfig.mediaUrl(category.image);
    return InkWell(
      key: Key('category-grid-${category.slug}'),
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: colors.sunken,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Icon(
                  Icons.grid_view_outlined,
                  color: colors.faint,
                  size: 32,
                ),
              )
            else
              Icon(Icons.grid_view_outlined,
                  color: colors.faint, size: 32),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.md, AppSpace.xl, AppSpace.md, AppSpace.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.scrim.withValues(alpha: 0),
                      scheme.scrim.withValues(alpha: 0.72),
                    ],
                  ),
                ),
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.productName(scheme.surface,
                      size: 14),
                ),
              ),
            ),
            if (category.productCount > 0)
              Positioned(
                top: AppSpace.sm,
                right: AppSpace.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '${category.productCount}',
                    style: AppTypography.tabularSmall(
                        scheme.onSurface,
                        size: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}