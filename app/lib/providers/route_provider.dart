import 'package:flutter/foundation.dart';
import '../models/route_models.dart';
import '../services/api_client.dart';

class RouteProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  bool loading = false;
  String? error;
  RouteResult? result;

  Future<void> calculate({
    required String origin,
    required String destination,
    required List<String> waypoints,
    required String transport,
  }) async {
    loading = true;
    error = null;
    result = null;
    notifyListeners();

    try {
      final json = await _client.post('/api/route', {
        'origin': origin,
        'destination': destination,
        'waypoints': waypoints,
        'transport': transport,
      });
      result = RouteResult.fromJson(json);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '확인 불가 ($e)';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
