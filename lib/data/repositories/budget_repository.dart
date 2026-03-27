import 'package:uuid/uuid.dart';
import '../datasources/local_database.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final _uuid = const Uuid();

  Future<List<BudgetModel>> getForMonth(String userId, int year, int month) async {
    final db = await LocalDatabase.database;
    final rows = await db.query('budgets',
      where: 'user_id = ? AND year = ? AND month = ?', whereArgs: [userId, year, month]);
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<BudgetModel> upsert({
    required String userId, required String category,
    required double limitAmount, required int month, required int year,
  }) async {
    final db = await LocalDatabase.database;
    final existing = await db.query('budgets',
      where: 'user_id = ? AND category = ? AND month = ? AND year = ?',
      whereArgs: [userId, category, month, year]);

    final budget = BudgetModel(
      id: existing.isEmpty ? _uuid.v4() : existing.first['id'] as String,
      userId: userId, category: category, limitAmount: limitAmount,
      month: month, year: year,
    );

    if (existing.isEmpty) {
      await db.insert('budgets', budget.toMap());
    } else {
      await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
    }
    return budget;
  }

  Future<void> delete(String id) async {
    final db = await LocalDatabase.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
