import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class CarRepository {
  Future<int> insert({ required String registration }) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    return await db.insert(carTable, { carRegistrationColumn: registration });
  }

  Future<List<Map<String, Object?>>> select({ int? carId, String? registration }) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (carId != null) {
      return await db.query(
        carTable,
        limit: 1,
        where: 'id = ?',
        whereArgs: [ carId ]
      );
    }

    if (registration != null) {
      return await db.query(
        carTable,
        limit: 1,
        where: 'registration = ?',
        whereArgs: [ registration ]
      );
    }

    return await db.query(carTable);
  }

  Future<int> delete({ int? carId }) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    if (carId == null) return await db.delete(carTable);

    return await db.delete(
      carTable,
      where: 'id = ?',
      whereArgs: [ carId ]
    );
  }

  Future<int> update({ required int carId, required String registration }) async {
    final db = DatabaseManager.getDatabaseOrThrow();

    return await db.update(carTable, {
      carRegistrationColumn: registration,
    }, where: 'id = ?', whereArgs: [ carId ]);
  }
}
