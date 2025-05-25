import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ligne/core/services/admin/car_provider.dart';
import 'package:ligne/ui/views/admin/car_selection_screen.dart';

class CarSelector extends StatelessWidget {
  const CarSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, provider, _) {
        return ListTile(
          leading: const Icon(Icons.directions_car),
          title: Text(
            provider.currentCar?.registration ?? 'No car selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: provider.cars.isNotEmpty && provider.cars.length > 1
              ? Text('${provider.cars.length} cars available')
              : null,
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CarSelectionScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
