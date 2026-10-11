import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/catalog_models.dart';

/// Trendy category tile (web-style): image avatar on top, name below.
/// Shared by the Home grid and the Search shortcuts rail so categories are
/// recognised by picture, not just by label.
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
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return InkWell(
      key: Key('category-tile-${category.slug}'),
      borderRadius: BorderRadius.circular(AppRadii.image),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.sunken,
              borderRadius: BorderRadius.circular(AppRadii.image),
            ),
            clipBehavior: Clip.antiAlias,
            child: (category.image ?? '').isEmpty
                ? Icon(Icons.grid_view_outlined,
                    color: colors.faint, size: size * 0.4)
                : CachedNetworkImage(
                    imageUrl: category.image!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.grid_view_outlined,
                      color: colors.faint,
                      size: size * 0.4,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: size + 16,
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption(scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}