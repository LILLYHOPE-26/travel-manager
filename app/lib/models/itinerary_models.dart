class ItineraryRequest {
  final String destination;
  final String city;
  final int totalDays;
  final String startDate;
  final String endDate;
  final List<String> styles;
  final String transport;
  final String specialRequests;

  ItineraryRequest({
    required this.destination,
    required this.city,
    required this.totalDays,
    required this.startDate,
    required this.endDate,
    required this.styles,
    required this.transport,
    required this.specialRequests,
  });

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'city': city,
        'totalDays': totalDays,
        'startDate': startDate,
        'endDate': endDate,
        'styles': styles,
        'transport': transport,
        'specialRequests': specialRequests,
      };
}

class ItineraryActivity {
  final String time;
  final String activity;
  final String place;
  final int durationMin;
  final String transport;
  final String memo;

  ItineraryActivity({
    required this.time,
    required this.activity,
    required this.place,
    required this.durationMin,
    required this.transport,
    required this.memo,
  });

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) => ItineraryActivity(
        time: json['time']?.toString() ?? '-',
        activity: json['activity']?.toString() ?? '-',
        place: json['place']?.toString() ?? '-',
        durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
        transport: json['transport']?.toString() ?? '-',
        memo: json['memo']?.toString() ?? '',
      );
}

class ItineraryDay {
  final int day;
  final List<ItineraryActivity> activities;

  ItineraryDay({required this.day, required this.activities});

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        day: (json['day'] as num?)?.toInt() ?? 0,
        activities: (json['activities'] as List<dynamic>? ?? [])
            .map((e) => ItineraryActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailySummary {
  final int day;
  final int totalTransportMin;
  final String estimatedCost;

  DailySummary({required this.day, required this.totalTransportMin, required this.estimatedCost});

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        day: (json['day'] as num?)?.toInt() ?? 0,
        totalTransportMin: (json['totalTransportMin'] as num?)?.toInt() ?? 0,
        estimatedCost: json['estimatedCost']?.toString() ?? '확인 불가',
      );
}

class ItineraryResult {
  final List<ItineraryDay> days;
  final List<DailySummary> dailySummary;

  ItineraryResult({required this.days, required this.dailySummary});

  factory ItineraryResult.fromJson(Map<String, dynamic> json) => ItineraryResult(
        days: (json['days'] as List<dynamic>? ?? [])
            .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailySummary: (json['dailySummary'] as List<dynamic>? ?? [])
            .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
