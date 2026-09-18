class ReceiptResult {
  final String merchant;
  final String date;
  final double amount;
  final String currency;
  final List<String> items;
  final String category;
  final bool categoryConfident;
  final double? exchangeRate;
  final double? krwAmount;
  final bool needManualRate;
  final String? fxReason;

  ReceiptResult({
    required this.merchant,
    required this.date,
    required this.amount,
    required this.currency,
    required this.items,
    required this.category,
    required this.categoryConfident,
    this.exchangeRate,
    this.krwAmount,
    required this.needManualRate,
    this.fxReason,
  });

  factory ReceiptResult.fromJson(Map<String, dynamic> json) => ReceiptResult(
        merchant: json['merchant']?.toString() ?? '(인식불가-확인필요)',
        date: json['date']?.toString() ?? '(인식불가-확인필요)',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency']?.toString() ?? '(인식불가-확인필요)',
        items: (json['items'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        category: json['category']?.toString() ?? '기타',
        categoryConfident: json['categoryConfident'] as bool? ?? false,
        exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
        krwAmount: (json['krwAmount'] as num?)?.toDouble(),
        needManualRate: json['needManualRate'] as bool? ?? false,
        fxReason: json['fxReason']?.toString(),
      );

  ReceiptResult copyWith({
    String? merchant,
    String? date,
    double? amount,
    String? currency,
    String? category,
    bool? categoryConfident,
    double? exchangeRate,
    double? krwAmount,
    bool? needManualRate,
    String? fxReason,
  }) =>
      ReceiptResult(
        merchant: merchant ?? this.merchant,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        items: items,
        category: category ?? this.category,
        categoryConfident: categoryConfident ?? this.categoryConfident,
        exchangeRate: exchangeRate,
        krwAmount: krwAmount,
        needManualRate: needManualRate ?? this.needManualRate,
        fxReason: fxReason,
      );

  ReceiptResult copyWithManualRate(double rate) {
    return copyWith(exchangeRate: rate, krwAmount: (amount * rate).roundToDouble(), needManualRate: false);
  }
}

class LedgerEntry {
  final int? id;
  final String date;
  final String merchant;
  final String category;
  final double amountOriginal;
  final String currency;
  final double exchangeRate;
  final double krwAmount;

  LedgerEntry({
    this.id,
    required this.date,
    required this.merchant,
    required this.category,
    required this.amountOriginal,
    required this.currency,
    required this.exchangeRate,
    required this.krwAmount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'merchant': merchant,
        'category': category,
        'amountOriginal': amountOriginal,
        'currency': currency,
        'exchangeRate': exchangeRate,
        'krwAmount': krwAmount,
      };

  factory LedgerEntry.fromMap(Map<String, dynamic> map) => LedgerEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        merchant: map['merchant'] as String,
        category: map['category'] as String,
        amountOriginal: (map['amountOriginal'] as num).toDouble(),
        currency: map['currency'] as String,
        exchangeRate: (map['exchangeRate'] as num).toDouble(),
        krwAmount: (map['krwAmount'] as num).toDouble(),
      );
}
