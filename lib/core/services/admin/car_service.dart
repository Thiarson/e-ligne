import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/data/models/local/car_model.dart';
import 'package:ligne/data/repositories/car_repository.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class CarService {
  final CarRepository _carRepository = CarRepository();
  CarModel? _currentCar;

  CarModel? get currentCar => _currentCar;

  Future<CarModel> addCar(String registration) async {
    await DatabaseManager().ensureDbIsOpen();
    final carId = await _carRepository.insert(registration: registration);
    final newCar = CarModel(id: carId, registration: registration);
    return newCar;
  }

  Future<void> setCurrentCar(CarModel car) async {
    _currentCar = car;
  }

  Future<CarModel> getCar(String registration) async {
    await DatabaseManager().ensureDbIsOpen();
    final cars = await _carRepository.select(registration: registration);
    final result = cars.first;
    return CarModel(
      id: result[carIdColumn] as int, 
      registration: result[carRegistrationColumn] as String
    );
  }

  Future<List<CarModel>> getAllCars() async {
    await DatabaseManager().ensureDbIsOpen();
    final carsData = await _carRepository.select();
    return carsData.map((carData) => CarModel(
      id: carData[carIdColumn] as int,
      registration: carData[carRegistrationColumn] as String,
    )).toList();
  }

  Future<void> deleteCar(int carId) async {
    await _carRepository.delete(carId: carId);
    if (_currentCar?.id == carId) {
      _currentCar = null;
    }
  }

  Future<void> updateCar(CarModel car) async {
    await _carRepository.update(
      carId: car.id,
      registration: car.registration,
    );
    if (_currentCar?.id == car.id) {
      _currentCar = car;
    }
  }
}
