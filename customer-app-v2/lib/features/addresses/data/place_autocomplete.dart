import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One address autocomplete hit.
class PlacePrediction {
  const PlacePrediction({required this.placeId, required this.description});

  final String placeId;
  final String description;

  factory PlacePrediction.fromPhoton(Map<String, dynamic> json) {
    final props =
        (json['properties'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    // Values arrive mixed (osm_id is numeric) — stringify defensively.
    String str(Object? value) => (value ?? '').toString();
    final bits = [
      str(props['name'].toString().isEmpty ? props['street'] : props['name']),
      str(props['city']),
      str(props['state']),
      str(props['postcode']),
    ].where((b) => b.isNotEmpty).toList();
    final osmType = str(props['osm_type']);
    final osmId = str(props['osm_id']);
    return PlacePrediction(
      placeId: '$osmType:$osmId',
      description: bits.join(', '),
    );
  }
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

  factory PlaceDetails.fromPhoton(Map<String, dynamic> props) =>
      PlaceDetails(
        line1: ((props['street'] ?? props['name'] ?? '').toString()),
        city: ((props['city'] ?? '').toString()),
        state: ((props['state'] ?? '').toString()),
        postalCode: ((props['postcode'] ?? '').toString()),
      );
}

/// Address autocomplete. Abstract for fake tests.
abstract class PlaceAutocompleteService {
  Future<List<PlacePrediction>> autocomplete(String input);

  Future<PlaceDetails?> details(String placeId);
}

/// Free, keyless autocomplete over Photon (OpenStreetMap data, fair use —
/// the sheet debounces keystrokes). No Google key, no billing account.
/// Predictions carry their address parts inline, so `details` resolves
/// from the last result set with no second network call.
class PhotonPlaceAutocompleteService implements PlaceAutocompleteService {
  PhotonPlaceAutocompleteService(this._dio);

  final Dio _dio;

  Map<String, Map<String, dynamic>> _cache = const {};

  @override
  Future<List<PlacePrediction>> autocomplete(String input) async {
    final q = input.trim();
    if (q.length < 3) return const [];
    final res = await _dio.get<Map<String, dynamic>>(
      'https://photon.komoot.io/api/',
      queryParameters: {'q': q, 'limit': 8, 'lang': 'en'},
    );
    final features = (res.data?['features'] as List?) ?? const [];
    final next = <String, Map<String, dynamic>>{};
    final out = <PlacePrediction>[];
    for (final feature in features.whereType<Map<String, dynamic>>()) {
      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      // India-only storefront.
      if ((props['countrycode'] ?? '') != 'IN') continue;
      final prediction = PlacePrediction.fromPhoton(feature);
      if (prediction.placeId == ':' || prediction.description.isEmpty) {
        continue;
      }
      next[prediction.placeId] = props;
      out.add(prediction);
      if (out.length >= 5) break;
    }
    _cache = next;
    return out;
  }

  @override
  Future<PlaceDetails?> details(String placeId) async {
    final props = _cache[placeId];
    if (props == null) return null;
    return PlaceDetails.fromPhoton(props);
  }
}

/// Always on: Photon needs no key and no billing, so the search box is a
/// permanent part of the address form (manual fields stay below it).
final placeAutocompleteProvider =
    Provider<PlaceAutocompleteService>((_) {
  return PhotonPlaceAutocompleteService(Dio());
});
