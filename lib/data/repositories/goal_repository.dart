import 'package:uuid/uuid.dart';
import '../datasources/local_database.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final _uuid = const Uuid();

  Future<List<GoalModel>> getAll(String userId) async {
    final db = await LocalDatabase.database;
    final rows = await db.query('goals', where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'created_at DESC');
    return rows.map(GoalModel.fromMap).toList();
  }

  Future<GoalModel> create({
    required String userId, required String name, required String emoji,
    required double targetAmount, DateTime? deadline,
  }) async {
    final db = await LocalDatabase.database;
    final goal = GoalModel(
      id: _uuid.v4(), userId: userId, name: name, emoji: emoji,
      targetAmount: targetAmount, savedAmount: 0,
      deadline: deadline, createdAt: DateTime.now(),
    );
    await db.insert('goals', goal.toMap());
    return goal;
  }

  Future<void> addSavings(String goalId, double amount) async {
    final db = await LocalDatabase.database;
    await db.rawUpdate(
      'UPDATE goals SET saved_amount = MIN(saved_amount + ?, target_amount) WHERE id = ?',
      [amount, goalId]);
  }

  Future<void> delete(String id) async {
    final db = await LocalDatabase.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
