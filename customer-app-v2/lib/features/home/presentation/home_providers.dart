import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../../models/catalog_models.dart';
import '../../../models/storefront_models.dart';

/// S4 · Home data: the platform render drives ticker/banners/rails/story;
/// the category grid reads the catalog (8 tiles + See all).
final homeStorefrontProvider = FutureProvider<StorefrontRender>(
  (ref) => ref.watch(catalogRepositoryProvider).platformStorefront(),
);

final homeCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// Fallback rails: rendered ONLY when the storefront carries no product
/// rows, so Home always shows products (Hot sales / Top rated / New).
final hotSalesProvider = FutureProvider<CatalogPage>(
  (ref) => ref.watch(catalogRepositoryProvider).products(isFeatured: true),
);

final topRatedProvider = FutureProvider<CatalogPage>(
  (ref) =>
      ref.watch(catalogRepositoryProvider).products(sort: 'rating'),
);

final newArrivalsProvider = FutureProvider<CatalogPage>(
  (ref) =>
      ref.watch(catalogRepositoryProvider).products(sort: 'newest'),
);