import 'package:flutter/foundation.dart';
import 'package:ligne/core/services/admin/car_service.dart';
import 'package:ligne/data/models/local/car_model.dart';

class CarProvider with ChangeNotifier {
  final CarService _carService;
  CarModel? _currentCar;
  List<CarModel> _cars = [];
  bool _isLoading = false;

  CarProvider(this._carService);

  CarModel? get currentCar => _currentCar;
  List<CarModel> get cars => _cars;
  bool get isLoading => _isLoading;

  Future<void> loadCars() async {
    _setLoading(true);
    try {
      _cars = await _carService.getAllCars();
      if (_cars.isNotEmpty && _currentCar == null) {
        _currentCar = _cars.first;
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }


  Future<void> addCar(String registration) async {
    _setLoading(true);
    try {
      final newCar = await _carService.addCar(registration);
      _cars.add(newCar);
      if (_currentCar == null) {
        _currentCar = newCar;
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setCurrentCar(CarModel car) async {
    if (_currentCar?.id != car.id) {
      await _carService.setCurrentCar(car);
      _currentCar = car;
      notifyListeners();
    }
  }

  Future<void> deleteCar(CarModel car) async {
    _setLoading(true);
    try {
      await _carService.deleteCar(car.id);
      _cars.removeWhere((c) => c.id == car.id);
      if (_currentCar?.id == car.id) {
        _currentCar = _cars.isNotEmpty ? _cars.first : null;
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
