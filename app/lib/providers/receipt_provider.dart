import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/receipt_models.dart';
import '../services/api_client.dart';
import '../services/ledger_db.dart';

class ReceiptProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  bool loading = false;
  bool rateLoading = false;
  String? error;
  ReceiptResult? result;
  bool saved = false;

  Map<String, double> categorySummary = {};
  List<LedgerEntry> todayEntries = [];

  // 1단계: 무료 로컬 OCR(Tesseract)로 영수증 텍스트를 인식한다 (환율은 아직 조회하지 않음).
  Future<void> recognize(File image) async {
    loading = true;
    error = null;
    result = null;
    saved = false;
    notifyListeners();

    try {
      final json = await _client.postImage('/api/receipt', image);
      result = ReceiptResult.fromJson(json);
      loading = false;
      notifyListeners();
      // 인식된 값(또는 사용자가 아직 수정하지 않은 기본값)으로 바로 환율을 시도한다.
      await applyRate(date: result!.date, currency: result!.currency, amount: result!.amount);
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
    } catch (e) {
      error = '확인 불가 ($e)';
      loading = false;
      notifyListeners();
    }
  }

  // 2단계: 사용자가 상호명/날짜/금액/통화를 확인·수정한 뒤 (다시) 환율을 계산한다.
  Future<void> applyRate({required String date, required String currency, required double amount}) async {
    if (result == null) return;
    rateLoading = true;
    notifyListeners();

    try {
      final json = await _client.get('/api/exchange-rate', {
        'date': date,
        'currency': currency,
        'amount': amount.toString(),
      });
      result = result!.copyWith(
        date: date,
        currency: currency,
        amount: amount,
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
        krwAmount: (json['krwAmount'] as num?)?.toDouble(),
        needManualRate: json['needManualRate'] as bool? ?? false,
        fxReason: json['fxReason']?.toString(),
      );
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '확인 불가 ($e)';
    } finally {
      rateLoading = false;
      notifyListeners();
    }
  }

  void applyManualRate(double rate) {
    if (result == null) return;
    result = result!.copyWithManualRate(rate);
    notifyListeners();
  }

  Future<void> saveToLedger({required String merchant, required String category}) async {
    final r = result;
    if (r == null || r.exchangeRate == null || r.krwAmount == null) return;

    final entry = LedgerEntry(
      date: r.date,
      merchant: merchant,
      category: category,
      amountOriginal: r.amount,
      currency: r.currency,
      exchangeRate: r.exchangeRate!,
      krwAmount: r.krwAmount!,
    );
    await LedgerDb.instance.insertEntry(entry);
    saved = true;
    await loadDaySummary(r.date);
    notifyListeners();
  }

  Future<void> loadDaySummary(String date) async {
    todayEntries = await LedgerDb.instance.getByDate(date);
    categorySummary = await LedgerDb.instance.getCategorySummary(date);
    notifyListeners();
  }
}
