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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16, right: 16, bottom: 8),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Colors.white, // Ensures the back button is white
              ),
              title: Text(
                'My Vehicles',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  onPressed: () => _showHelpDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.1],
                )
              : null,
        ),
        child: Consumer<CarProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Search and Add Car Section
                _buildHeaderSection(context, provider),
                
                // Status Indicator
                if (provider.isLoading && provider.cars.isEmpty)
                  const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent)
                else
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: isDark ? Colors.white12 : Colors.grey[200],
                  ),
                
                // Cars List
                Expanded(
                  child: _buildCarsList(provider),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCarDialog(context),
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, CarProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.cars.isNotEmpty) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : theme.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : theme.primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Select a vehicle to view details or add a new one',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : theme.primaryColor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 8),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            provider.setCurrentCar(car);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(
                      color: theme.primaryColor,
                      width: 1.5,
                    )
                  : Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Car Icon with Status
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primaryColor.withOpacity(0.1)
                          : isDark 
                              ? Colors.grey[800]
                              : Colors.grey[50],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.3)
                            : isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 28,
                      color: isSelected
                          ? theme.primaryColor
                          : isDark
                              ? Colors.grey[300]
                              : Colors.grey[600],
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
                  icon: Icon(Icons.more_vert, 
                    color: Theme.of(context).hintColor,
                  ),
                  onPressed: () => _showCarOptions(context, car, provider),
                ),
            ]),
          ),
        ),
      ),
      ),
    );
  }
  
  Widget _buildEmptyState(CarProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? theme.primaryColor.withOpacity(0.3) : theme.primaryColor.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 56,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No Vehicles Added',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'You haven\'t added any vehicles yet. Add your first vehicle to get started with tracking your trips and expenses.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddCarDialog(context),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Add First Vehicle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 40),
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
