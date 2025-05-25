import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class IncomeRepository {
  Future<int> insert({
    required int carId,
    required String description,
    required int amount,
    required String source,
    required DateTime date,
  }) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    return await db.insert(incomeTable, {
      incomeCarIdColumn: carId,
      incomeDescriptionColumn: description,
      incomeAmountColumn: amount.toString(), // Store amount as string
      incomeSourceColumn: source,
      incomeDateColumn: date.toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> select({
    DateTime? date,
    int? incomeId,
    int? carId,
  }) async {
    final db = DatabaseManager.getDatabaseOrThrow();
    final List<dynamic> whereArgs = [];
    final List<String> whereConditions = [];

    if (incomeId != null) {
      whereConditions.add('id = ?');
      whereArgs.add(incomeId);
    }

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      whereConditions.add('$incomeDateColumn >= ? AND $incomeDateColumn < ?');
      whereArgs.addAll([startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    }

    if (carId != null) {
      whereConditions.add('$incomeCarIdColumn = ?');
      whereArgs.add(carId);
    }

    String? whereClause;
    if (whereConditions.isNotEmpty) {
      whereClause = whereConditions.join(' AND ');
    }

    return await db.query(
      incomeTable,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  Future<int> delete({ int? incomeId }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (incomeId == null) return db.delete(incomeTable);

    return db.delete(
      incomeTable, 
      where: 'id = ?', 
      whereArgs: [ incomeId ]
    );
  }

  Future<int> update({
    required int incomeId,
    required String description,
    required int amount,
    required String source,
  }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    return db.update(incomeTable, {
      incomeDescriptionColumn: description,
      incomeAmountColumn: amount,
      incomeSourceColumn: source,
    }, where: 'id = ?', whereArgs: [ incomeId ]);
  }
}
