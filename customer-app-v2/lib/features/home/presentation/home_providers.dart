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