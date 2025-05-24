import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class ExpenseRepository {
  Future<int> insert({
    required int carId,
    required String description,
    required String amount,
    required String source,
  }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    return db.insert(expenseTable, {
      expenseCarIdColumn: carId,
      expenseDescriptionColumn: description,
      expenseAmountColumn: amount,
      expenseSourcecolumn: source,
    });
  }

  Future<List<Map<String, Object?>>> select({ int? expenseId}) {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (expenseId == null) return db.query(expenseTable);

    return db.query(
      expenseTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [ expenseId ],
    );
  }

  Future<int> delete({ int? expenseId }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (expenseId == null) return db.delete(expenseTable);

    return db.delete(
      expenseTable, 
      where: 'id = ?', 
      whereArgs: [ expenseId ]
    );
  }

  Future<int> update({
    required int expenseId,
    required String description,
    required String amount,
    required String source,
  }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    return db.update(expenseTable, {
      expenseDescriptionColumn: description,
      expenseAmountColumn: amount,
      expenseSourcecolumn: source,
    }, where: 'id = ?', whereArgs: [ expenseId ]);
  }
}
