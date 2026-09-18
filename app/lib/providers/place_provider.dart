import 'package:flutter/foundation.dart';
import '../models/place_models.dart';
import '../services/api_client.dart';

class PlaceProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  bool loading = false;
  String? error;
  PlaceSearchResult? result;

  Future<void> search(String region) async {
    loading = true;
    error = null;
    result = null;
    notifyListeners();

    try {
      final json = await _client.get('/api/places', {'region': region});
      result = PlaceSearchResult.fromJson(json);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '확인 불가 ($e)';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> searchByCandidate(PlaceCandidate candidate) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final json = await _client.get('/api/places', {
        'lat': candidate.lat.toString(),
        'lng': candidate.lng.toString(),
      });
      result = PlaceSearchResult.fromJson(json);
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
