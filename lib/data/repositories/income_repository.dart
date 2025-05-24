import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class IncomeRepository {
  Future<int> insert({
    required int carId,
    required String description,
    required String amount,
    required String source,
  }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    return db.insert(incomeTable, {
      incomeCarIdColumn: carId,
      incomeDescriptionColumn: description,
      incomeAmountColumn: amount,
      incomeSourcecolumn: source,
    });
  }

  Future<List<Map<String, Object?>>> select({ int? incomeId }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (incomeId == null) return db.query(incomeTable);

    return db.query(
      incomeTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [ incomeId ],
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
    required String amount,
    required String source,
  }) {
    final db = DatabaseManager.getDatabaseOrThrow();

    return db.update(incomeTable, {
      incomeDescriptionColumn: description,
      incomeAmountColumn: amount,
      incomeSourcecolumn: source,
    }, where: 'id = ?', whereArgs: [ incomeId ]);
  }
}
