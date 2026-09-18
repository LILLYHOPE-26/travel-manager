import 'package:flutter/foundation.dart';
import '../models/itinerary_models.dart';
import '../services/api_client.dart';

class ItineraryProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  bool loading = false;
  String? error;
  ItineraryResult? result;

  Future<void> generate(ItineraryRequest request) async {
    loading = true;
    error = null;
    result = null;
    notifyListeners();

    try {
      final json = await _client.post('/api/itinerary', request.toJson());
      result = ItineraryResult.fromJson(json);
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
