import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/receipt_models.dart';

class LedgerDb {
  static final LedgerDb instance = LedgerDb._internal();
  LedgerDb._internal();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'ledger.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE ledger(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          merchant TEXT NOT NULL,
          category TEXT NOT NULL,
          amountOriginal REAL NOT NULL,
          currency TEXT NOT NULL,
          exchangeRate REAL NOT NULL,
          krwAmount REAL NOT NULL
        )
      '''),
    );
    return _db!;
  }

  Future<int> insertEntry(LedgerEntry entry) async {
    final db = await _open();
    final map = entry.toMap()..remove('id');
    return db.insert('ledger', map);
  }

  Future<List<LedgerEntry>> getByDate(String date) async {
    final db = await _open();
    final rows = await db.query('ledger', where: 'date = ?', whereArgs: [date], orderBy: 'id DESC');
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<Map<String, double>> getCategorySummary(String date) async {
    final db = await _open();
    final rows = await db.rawQuery(
      'SELECT category, SUM(krwAmount) as total FROM ledger WHERE date = ? GROUP BY category',
      [date],
    );
    return {for (final row in rows) row['category'] as String: (row['total'] as num).toDouble()};
  }
}
