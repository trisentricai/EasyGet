import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/review_model.dart';

/// Product reviews. Abstract for fake tests.
abstract class ReviewRepository {
  Future<List<Review>> list(String slug);

  Future<Review> create(
    String slug, {
    required int rating,
    String title = '',
    String body = '',
  });
}

class HttpReviewRepository implements ReviewRepository {
  HttpReviewRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Review>> list(String slug) async {
    final json = await _api.get<dynamic>(ApiEndpoints.productReviews(slug));
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();
  }

  @override
  Future<Review> create(
    String slug, {
    required int rating,
    String title = '',
    String body = '',
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.productReviews(slug),
      body: {'rating': rating, 'title': title, 'body': body},
      decode: (j) => (j as Map<String, dynamic>),
    );
    return Review.fromJson(json);
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return HttpReviewRepository(ref.watch(apiClientProvider));
});