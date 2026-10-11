import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

/// One Google Places autocomplete hit.
class PlacePrediction {
  const PlacePrediction({required this.placeId, required this.description});

  final String placeId;
  final String description;

  factory PlacePrediction.fromJson(Map<String, dynamic> json) =>
      PlacePrediction(
        placeId: (json['place_id'] ?? '') as String,
        description: (json['description'] ?? '') as String,
      );
}

/// Resolved address parts for a picked place (India-shaped).
class PlaceDetails {
  const PlaceDetails({
    this.line1 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
  });

  final String line1;
  final String city;
  final String state;
  final String postalCode;
}

/// Address autocomplete over the Google Places HTTP API (no native plugin,
/// no extra dependency). Restricted to Indian addresses.
abstract class PlaceAutocompleteService {
  Future<List<PlacePrediction>> autocomplete(String input);

  Future<PlaceDetails?> details(String placeId);
}

class HttpPlaceAutocompleteService implements PlaceAutocompleteService {
  HttpPlaceAutocompleteService(this._dio, this._apiKey);

  final Dio _dio;
  final String _apiKey;

  static const _base = 'https://maps.googleapis.com/maps/api/place';

  @override
  Future<List<PlacePrediction>> autocomplete(String input) async {
    final q = input.trim();
    if (q.length < 3) return const [];
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/autocomplete/json',
      queryParameters: {
        'input': q,
        'key': _apiKey,
        'components': 'country:IN',
        'types': 'address',
      },
    );
    final rows = (res.data?['predictions'] as List?) ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PlacePrediction.fromJson)
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  @override
  Future<PlaceDetails?> details(String placeId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/details/json',
      queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'fields': 'address_component',
      },
    );
    final components =
        (res.data?['result']?['address_components'] as List?) ?? const [];
    String pick(String type) {
      for (final c in components.whereType<Map<String, dynamic>>()) {
        final types = (c['types'] as List?)?.map((e) => '$e') ?? const [];
        if (types.contains(type)) return (c['long_name'] ?? '') as String;
      }
      return '';
    }

    final street = pick('street_number');
    final route = pick('route');
    final line1 = '$street $route'.trim();
    return PlaceDetails(
      line1: line1,
      city: pick('locality'),
      state: pick('administrative_area_level_1'),
      postalCode: pick('postal_code'),
    );
  }
}

/// Null when no `PLACES_API_KEY` is baked in — sheets fall back to manual
/// entry instead of showing a dead search box.
final placeAutocompleteProvider =
    Provider<PlaceAutocompleteService?>((_) {
  if (AppConfig.placesApiKey.isEmpty) return null;
  return HttpPlaceAutocompleteService(Dio(), AppConfig.placesApiKey);
});