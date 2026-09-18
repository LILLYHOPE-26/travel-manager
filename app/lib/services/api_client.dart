import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.backendBaseUrl}$path');
    try {
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('확인 불가 (서버에 연결할 수 없습니다)');
    }
  }

  Future<Map<String, dynamic>> get(String path, Map<String, String> query) async {
    final uri = Uri.parse('${ApiConfig.backendBaseUrl}$path').replace(queryParameters: query);
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 30));
      return _handleResponse(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('확인 불가 (서버에 연결할 수 없습니다)');
    }
  }

  Future<Map<String, dynamic>> postImage(String path, File image) async {
    final uri = Uri.parse('${ApiConfig.backendBaseUrl}$path');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _handleResponse(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('확인 불가 (서버에 연결할 수 없습니다)');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      final missing = (decoded['missingFields'] as List<dynamic>?)?.join(', ');
      final message = (missing != null && missing.isNotEmpty)
          ? '입력값 부족: $missing'
          : (decoded['error']?.toString() ?? '확인 불가');
      throw ApiException(message);
    }
    return decoded;
  }
}
