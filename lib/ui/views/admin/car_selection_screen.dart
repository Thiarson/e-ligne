import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ligne/core/services/admin/car_provider.dart';
import 'package:ligne/data/models/local/car_model.dart';

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({Key? key}) : super(key: key);

  @override
  _CarSelectionScreenState createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  final TextEditingController _registrationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarProvider>().loadCars();
    });
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _addCar() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<CarProvider>().addCar(_registrationController.text.trim());
      _registrationController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cars'),
        centerTitle: true,
      ),
      body: Consumer<CarProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.cars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Add new car form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _registrationController,
                          decoration: const InputDecoration(
                            labelText: 'Car Registration',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter registration';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addCar,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
              // Cars list
              Expanded(
                child: provider.cars.isEmpty
                    ? const Center(child: Text('No cars added yet'))
                    : ListView.builder(
                        itemCount: provider.cars.length,
                        itemBuilder: (context, index) {
                          final car = provider.cars[index];
                          final isSelected = provider.currentCar?.id == car.id;
                          return ListTile(
                            title: Text(
                              car.registration,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Colors.green),
                                if (provider.cars.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, car),
                                  ),
                              ],
                            ),
                            onTap: () {
                              provider.setCurrentCar(car);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CarModel car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.registration}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<CarProvider>().deleteCar(car);
    }
  }
}
