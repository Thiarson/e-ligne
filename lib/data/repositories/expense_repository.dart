import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class ExpenseRepository {
  Future<int> insert({
    required int carId,
    required String description,
    required int amount,
    required String source,
    required DateTime date,
  }) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    return await db.insert(expenseTable, {
      expenseCarIdColumn: carId,
      expenseDescriptionColumn: description,
      expenseAmountColumn: amount.toString(), // Store amount as string
      expenseSourceColumn: source,
      expenseDateColumn: date.toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> select({DateTime? date, int? expenseId}) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (expenseId != null) {
      return await db.query(
        expenseTable,
        limit: 1,
        where: 'id = ?',
        whereArgs: [expenseId],
      );
    }

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return await db.query(
        expenseTable,
        where: '$expenseDateColumn >= ? AND $expenseDateColumn < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );
    }

    // If no filters are provided, return all records
    return await db.query(expenseTable);
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
    required int amount,
    required String source,
  }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    return db.update(expenseTable, {
      expenseDescriptionColumn: description,
      expenseAmountColumn: amount,
      expenseSourceColumn: source,
    }, where: 'id = ?', whereArgs: [ expenseId ]);
  }
}
