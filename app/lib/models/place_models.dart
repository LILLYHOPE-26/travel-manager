class Attraction {
  final String name;
  final String feature;
  final int distanceM;
  final int walkMin;

  Attraction({required this.name, required this.feature, required this.distanceM, required this.walkMin});

  factory Attraction.fromJson(Map<String, dynamic> json) => Attraction(
        name: json['name']?.toString() ?? '확인 불가',
        feature: json['feature']?.toString() ?? '-',
        distanceM: (json['distanceM'] as num?)?.toInt() ?? 0,
        walkMin: (json['walkMin'] as num?)?.toInt() ?? 0,
      );
}

class RestaurantRec {
  final int rank;
  final String name;
  final String mainMenu;
  final int distanceM;
  final String reason;

  RestaurantRec({
    required this.rank,
    required this.name,
    required this.mainMenu,
    required this.distanceM,
    required this.reason,
  });

  factory RestaurantRec.fromJson(Map<String, dynamic> json) => RestaurantRec(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '확인 불가',
        mainMenu: json['mainMenu']?.toString() ?? '-',
        distanceM: (json['distanceM'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '-',
      );
}

class PlaceCandidate {
  final String name;
  final String placeId;
  final double lat;
  final double lng;

  PlaceCandidate({required this.name, required this.placeId, required this.lat, required this.lng});

  factory PlaceCandidate.fromJson(Map<String, dynamic> json) => PlaceCandidate(
        name: json['name']?.toString() ?? '',
        placeId: json['placeId']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );
}

class PlaceSearchResult {
  final bool ambiguous;
  final List<PlaceCandidate> candidates;
  final List<Attraction> attractions;
  final List<RestaurantRec> restaurants;

  PlaceSearchResult({
    required this.ambiguous,
    required this.candidates,
    required this.attractions,
    required this.restaurants,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) => PlaceSearchResult(
        ambiguous: json['ambiguous'] as bool? ?? false,
        candidates: (json['candidates'] as List<dynamic>? ?? [])
            .map((e) => PlaceCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        attractions: (json['attractions'] as List<dynamic>? ?? [])
            .map((e) => Attraction.fromJson(e as Map<String, dynamic>))
            .toList(),
        restaurants: (json['restaurants'] as List<dynamic>? ?? [])
            .map((e) => RestaurantRec.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
