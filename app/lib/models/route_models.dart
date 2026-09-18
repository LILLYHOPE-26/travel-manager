class RouteLeg {
  final String from;
  final String to;
  final int distanceM;
  final int durationMin;
  final String source;

  RouteLeg({required this.from, required this.to, required this.distanceM, required this.durationMin, required this.source});

  factory RouteLeg.fromJson(Map<String, dynamic> json) => RouteLeg(
        from: json['from']?.toString() ?? '-',
        to: json['to']?.toString() ?? '-',
        distanceM: (json['distanceM'] as num?)?.toInt() ?? 0,
        durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
        source: json['source']?.toString() ?? '확인 불가',
      );
}

class RouteResult {
  final List<RouteLeg> legs;
  final int totalDistanceM;
  final int totalDurationMin;

  RouteResult({required this.legs, required this.totalDistanceM, required this.totalDurationMin});

  factory RouteResult.fromJson(Map<String, dynamic> json) => RouteResult(
        legs: (json['legs'] as List<dynamic>? ?? []).map((e) => RouteLeg.fromJson(e as Map<String, dynamic>)).toList(),
        totalDistanceM: (json['totalDistanceM'] as num?)?.toInt() ?? 0,
        totalDurationMin: (json['totalDurationMin'] as num?)?.toInt() ?? 0,
      );
}
