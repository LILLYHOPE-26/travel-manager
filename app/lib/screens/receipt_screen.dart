import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/receipt_models.dart';
import '../providers/receipt_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

const _categories = ['식비', '교통', '숙박', '쇼핑', '입장료/관광', '기타'];

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  File? _image;
  final _merchantController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController();
  final _manualRateController = TextEditingController();
  String _category = '기타';
  bool _fieldsInitialized = false;

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _fieldsInitialized = false;
      });
    }
  }

  void _initFieldsIfNeeded(ReceiptResult? receiptResult) {
    if (_fieldsInitialized || receiptResult == null) return;
    _merchantController.text = receiptResult.merchant;
    _dateController.text = receiptResult.date;
    _amountController.text = receiptResult.amount.toString();
    _currencyController.text = receiptResult.currency == '(인식불가-확인필요)' ? '' : receiptResult.currency;
    _category = _categories.contains(receiptResult.category) ? receiptResult.category : '기타';
    _fieldsInitialized = true;
  }

  void _recalculate(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || _dateController.text.trim().isEmpty || _currencyController.text.trim().isEmpty) return;
    context.read<ReceiptProvider>().applyRate(
          date: _dateController.text.trim(),
          currency: _currencyController.text.trim().toUpperCase(),
          amount: amount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final result = provider.result;
    _initFieldsIfNeeded(result);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('촬영'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text('갤러리'),
              ),
            ],
          ),
          if (_image != null) ...[
            const SizedBox(height: 12),
            Image.file(_image!, height: 180),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.loading
                  ? null
                  : () {
                      setState(() => _fieldsInitialized = false);
                      context.read<ReceiptProvider>().recognize(_image!);
                    },
              child: const Text('인식하기'),
            ),
          ],
          const SizedBox(height: 16),
          if (provider.loading) const LoadingView(),
          if (provider.error != null) ErrorView(message: provider.error!),
          if (result != null) ...[
            const Text(
              '※ 무료 로컬 OCR 인식 결과입니다. 정확하지 않을 수 있으니 아래 내용을 확인·수정해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            TextField(controller: _merchantController, decoration: const InputDecoration(labelText: '상호명')),
            const SizedBox(height: 8),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: '결제일자 (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '결제금액'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _currencyController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: '통화(USD 등)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: result.categoryConfident ? '카테고리' : '카테고리 (추정 분류 - 확인 필요)',
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? '기타'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: provider.rateLoading ? null : () => _recalculate(context),
              child: Text(provider.rateLoading ? '환율 계산 중...' : '환율 다시 계산'),
            ),
            const SizedBox(height: 12),
            Text(
              '적용환율: ${result.exchangeRate?.toStringAsFixed(2) ?? '-'} · 원화환산액: ${result.krwAmount != null ? '${result.krwAmount!.toStringAsFixed(0)}원' : '-'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (result.needManualRate) ...[
              const SizedBox(height: 12),
              Text('환율 자동 조회 불가${result.fxReason != null ? " (${result.fxReason})" : ""}. 해당일 환율을 직접 입력해주세요.'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: '1 ${result.currency} = ? KRW'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final rate = double.tryParse(_manualRateController.text);
                      if (rate != null) context.read<ReceiptProvider>().applyManualRate(rate);
                    },
                    child: const Text('적용'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (!result.needManualRate && result.krwAmount != null)
              FilledButton(
                onPressed: () {
                  context.read<ReceiptProvider>().saveToLedger(
                        merchant: _merchantController.text.trim(),
                        category: _category,
                      );
                },
                child: Text(provider.saved ? '저장됨' : '가계부에 저장'),
              ),
            const SizedBox(height: 16),
            if (provider.todayEntries.isNotEmpty) ...[
              const Divider(),
              Text(
                '■ 당일 지출 합계(원화): ${provider.todayEntries.fold<double>(0, (sum, e) => sum + e.krwAmount).toStringAsFixed(0)}원',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '■ 카테고리별 합계: ${provider.categorySummary.entries.map((e) => '${e.key} ${e.value.toStringAsFixed(0)}원').join(' / ')}',
              ),
            ],
          ],
        ],
      ),
    );
  }
}
