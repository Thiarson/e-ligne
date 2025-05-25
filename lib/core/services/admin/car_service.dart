import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/data/models/local/car_model.dart';
import 'package:ligne/data/repositories/car_repository.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class CarService {
  final CarRepository _carRepository = CarRepository();

  Future<CarModel> addCar(String registration) async {
    await DatabaseManager().ensureDbIsOpen();

    final carId = await _carRepository.insert(registration: registration);

    final newCar = CarModel(id: carId, registration: registration);
    return newCar;
  }

  Future<CarModel> getCar(String registration) async {
    await DatabaseManager().ensureDbIsOpen();

    final cars = await _carRepository.select(registration: registration);
    final result = cars.first;

    final car = CarModel(
      id: result[carIdColumn] as int, 
      registration: result[carRegistrationColumn] as String
    );
    return car;
  }
}
