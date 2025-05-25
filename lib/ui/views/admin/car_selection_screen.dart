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
      try {
        await context.read<CarProvider>().addCar(_registrationController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vehicle added successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        _registrationController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add vehicle: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: AppBar(
            title: Text(
              'My Vehicles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showHelpDialog(context),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<CarProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Search and Add Car Section
              _buildHeaderSection(context, provider),
              
              // Status Indicator
              if (provider.isLoading && provider.cars.isEmpty)
                const LinearProgressIndicator(minHeight: 2)
              else
                const Divider(height: 1, thickness: 1),
              
              // Cars List
              Expanded(
                child: _buildCarsList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCarDialog(context),
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Add Vehicle'),
        elevation: 2,
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, CarProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (provider.cars.isNotEmpty)
            Center(
              child: Text(
                'Select a vehicle to view details or add a new one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarsList(CarProvider provider) {
    if (provider.isLoading && provider.cars.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.cars.isEmpty) {
      return _buildEmptyState(provider);
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCars(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.cars.length,
        itemBuilder: (context, index) {
          final car = provider.cars[index];
          final isSelected = provider.currentCar?.id == car.id;
          
          return _buildCarCard(context, car, isSelected, provider);
        },
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, CarModel car, bool isSelected, CarProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          provider.setCurrentCar(car);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Car Icon with Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 28,
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Car Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.registration,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last used: 2 days ago', // TODO: Add last used date to car model
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (provider.cars.length > 1)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showCarOptions(context, car, provider),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(CarProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Theme.of(context).hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Vehicles Added',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Add your first vehicle to get started with tracking your trips and maintenance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCarDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add First Vehicle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCarDialog(BuildContext context) async {
    _registrationController.clear();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter vehicle registration number',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'e.g., ABC 123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter registration';
                  }
                  if (value.length < 3) {
                    return 'Enter a valid registration';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                await _addCar();
              }
            },
            child: const Text('ADD VEHICLE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCarOptions(BuildContext context, CarModel car, CarProvider provider) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blue),
              title: const Text('Set as Default'),
              onTap: () => Navigator.pop(context, 'set_default'),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Details'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Vehicle'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Cancel', textAlign: TextAlign.center),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );

    switch (result) {
      case 'set_default':
        provider.setCurrentCar(car);
        if (mounted) {
          Navigator.pop(context);
        }
        break;
      case 'edit':
        // TODO: Implement edit functionality
        break;
      case 'delete':
        _confirmDelete(context, car);
        break;
      default:
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context, CarModel car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Vehicle'),
        content: Text(
          'Are you sure you want to remove ${car.registration}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'REMOVE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<CarProvider>().deleteCar(car);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle removed successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove vehicle: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }
  
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Your Vehicles'),
        content: const Text(
          '• Tap on a vehicle to select it as your active vehicle\n\n'
          '• Swipe left on a vehicle to quickly access actions\n\n'
          '• Add multiple vehicles to easily switch between them',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}
