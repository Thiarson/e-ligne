import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/core/enums/menu_action.dart';
import 'package:ligne/core/services/admin/car_provider.dart';
import 'package:ligne/core/services/admin/admin_service.dart';
import 'package:ligne/data/models/local/financial_entry_model.dart';
import 'package:ligne/data/repositories/income_repository.dart';
import 'package:ligne/data/repositories/expense_repository.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/views/admin/car_selection_screen.dart';
import 'package:ligne/ui/widgets/loading/loading_indicator.dart';
import 'package:ligne/utils/helpers/db_manager.dart';
import 'package:ligne/utils/dialogs/logout_dialog.dart';
import 'package:ligne/utils/dialogs/add_financial_dialog.dart';
import 'package:ligne/ui/widgets/sync_button.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  late final AdminService _adminService;
  bool _isLoading = false;
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _balance = 0;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load cars when the view initializes
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      carProvider.loadCars().then((_) {
        if (carProvider.currentCar == null && carProvider.cars.isNotEmpty) {
          carProvider.setCurrentCar(carProvider.cars.first);
        } else if (carProvider.currentCar != null) {
          _loadFinancialData();
        }
      });
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload financial data when the current car changes
    final carProvider = Provider.of<CarProvider>(context);
    if (carProvider.currentCar != null) {
      _loadFinancialData();
    }
  }

  Future<void> _loadFinancialData() async {
    if (_selectedDay == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    if (carProvider.currentCar == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Process balance carryover first for the selected car
      await _adminService.processBalanceCarryover(
        _selectedDay!,
        carProvider.currentCar!.id,
      );
      
      // Then get the updated financial data for the selected car
      final totalIncome = await _adminService.getTotalIncome(
        _selectedDay!,
        carProvider.currentCar!.id,
      );
      final totalExpense = await _adminService.getTotalExpense(
        _selectedDay!,
        carProvider.currentCar!.id,
      );
      final balance = await _adminService.getBalance(
        _selectedDay!,
        carProvider.currentCar!.id,
      );
      
      if (mounted) {
        setState(() {
          _totalIncome = totalIncome;
          _totalExpense = totalExpense;
          _balance = balance;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading financial data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddIncomeDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final sourceController = TextEditingController();
    final carProvider = Provider.of<CarProvider>(context, listen: false);

    if (carProvider.currentCar == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a car first')),
        );
      }
      return;
    }

    final result = await showAddFinancialDialog(
      context, 
      descriptionController, 
      amountController, 
      sourceController,
      FinancialType.income,
    );

    if (result == true && _selectedDay != null) {
      try {
        final amount = int.tryParse(amountController.text) ?? 0;
        final entry = IncomeModel(
          id: 0, // Will be set by the database
          carId: carProvider.currentCar!.id,
          description: descriptionController.text,
          amount: amount,
          date: _selectedDay!,
          source: sourceController.text,
        );
        
        await _adminService.addIncomeEntry(entry: entry, carId: carProvider.currentCar!.id);
        if (mounted) {
          await _loadFinancialData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add income: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _showAddExpenseDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final sourceController = TextEditingController();
    final carProvider = Provider.of<CarProvider>(context, listen: false);

    if (carProvider.currentCar == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a car first')),
        );
      }
      return;
    }

    final result = await showAddFinancialDialog(
      context, 
      descriptionController, 
      amountController, 
      sourceController,
      FinancialType.expense,
    );

    if (result == true && _selectedDay != null) {
      try {
        final amount = int.tryParse(amountController.text) ?? 0;
        final entry = ExpenseModel(
          id: 0, // Will be set by the database
          carId: carProvider.currentCar!.id,
          description: descriptionController.text,
          amount: amount,
          date: _selectedDay!,
          source: sourceController.text,
        );
        
        await _adminService.addExpenseEntry(entry: entry, carId: carProvider.currentCar!.id);
        if (mounted) {
          await _loadFinancialData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add expense: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _showFinancialDetails(bool isIncome) async {
    if (_selectedDay == null) return;
    
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    if (carProvider.currentCar == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a car first')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      List<Map<String, dynamic>> entries;
      final currentCarId = carProvider.currentCar!.id;
      
      if (isIncome) {
        final incomeRepo = IncomeRepository();
        await DatabaseManager().ensureDbIsOpen();
        entries = await incomeRepo.select(
          date: _selectedDay!,
          carId: currentCarId,
        );
      } else {
        final expenseRepo = ExpenseRepository();
        await DatabaseManager().ensureDbIsOpen();
        entries = await expenseRepo.select(
          date: _selectedDay!,
          carId: currentCarId,
        );
      }

      if (!mounted) return;

      final totalAmount = entries.fold<int>(0, (sum, entry) {
        final amountStr = isIncome 
            ? (entry[incomeAmountColumn] as String?) ?? '0'
            : (entry[expenseAmountColumn] as String?) ?? '0';
        return sum + (int.tryParse(amountStr) ?? 0);
      });

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : Colors.black87;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isIncome ? 'Income Details' : 'Expense Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: isIncome ? Colors.green[700] : Colors.red[700],
                                  size: 22,
                                ),
                              ),
                              onPressed: isIncome ? _showAddIncomeDialog : _showAddExpenseDialog,
                              splashRadius: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: (isIncome ? Colors.green[50] : Colors.red[50])?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isIncome ? Colors.green : Colors.red).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total ${isIncome ? 'Income' : 'Expense'}:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (isIncome ? Colors.green[100] : Colors.red[100])?.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: 'Ar ', decimalDigits: 0).format(totalAmount)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isIncome ? Colors.green[800] : Colors.red[800],
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // List of entries
                  if (entries.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]!
                            : Colors.grey[50]!,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (isIncome ? Colors.green[50] : Colors.red[50])?.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.account_balance_wallet_rounded : Icons.money_off_csred_rounded,
                              size: 40,
                              color: isIncome ? Colors.green[600] : Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No ${isIncome ? 'Income' : 'Expense'} Recorded',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isIncome 
                                ? 'Start by adding your first income source' 
                                : 'Track your expenses to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isIncome ? _showAddIncomeDialog : _showAddExpenseDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isIncome ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: (isIncome ? Colors.green : Colors.red).withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Add ${isIncome ? 'Income' : 'Expense'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]!
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          if (Theme.of(context).brightness == Brightness.light)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final String amountStr = isIncome 
                              ? (entry[incomeAmountColumn] as String?) ?? '0'
                              : (entry[expenseAmountColumn] as String?) ?? '0';
                          final int amount = int.tryParse(amountStr) ?? 0;
                          
                          final description = isIncome
                              ? (entry[incomeDescriptionColumn] as String? ?? 'No description')
                              : (entry[expenseDescriptionColumn] as String? ?? 'No description');
                              
                          final source = isIncome
                              ? (entry[incomeSourceColumn] as String? ?? 'No source')
                              : (entry[expenseSourceColumn] as String? ?? 'No source');
                          
                          final date = entry['date'] != null 
                              ? DateTime.parse(entry['date'].toString())
                              : DateTime.now();
                          
                          return Dismissible(
                            key: Key(entry['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                            ),
                            confirmDismiss: (direction) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete this ${isIncome ? 'income' : 'expense'}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              return confirmed ?? false;
                            },
                            onDismissed: (direction) async {
                              try {
                                if (isIncome) {
                                  await _adminService.deleteIncomeEntry(entry['id']);
                                } else {
                                  await _adminService.deleteExpenseEntry(entry['id']);
                                }
                                if (mounted) {
                                  setState(() {
                                    entries.removeAt(index);
                                    _loadFinancialData();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${isIncome ? 'Income' : 'Expense'} deleted'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        textColor: Colors.blue,
                                        onPressed: () {
                                          // TODO: Implement undo functionality
                                        },
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Implement edit functionality
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (isIncome ? Colors.green[50] : Colors.red[50])?.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          size: 20,
                                          color: isIncome ? Colors.green[600] : Colors.red[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              description,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).textTheme.titleMedium?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.label_important_outline_rounded,
                                                  size: 14,
                                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  source,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: 'Ar ', decimalDigits: 0).format(amount)}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isIncome ? Colors.green[700] : Colors.red[700],
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM d, h:mm a').format(date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show vehicle details in a bottom sheet
  void _showVehicleDetails(BuildContext context, String registration) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active • Last updated: ${DateFormat('MMM d, y').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.credit_card, 'Registration', registration),
            _buildDetailRow(Icons.calendar_today, 'Added on', DateFormat('MMM d, y').format(DateTime.now())),
            _buildDetailRow(Icons.speed, 'Total Trips', '24 trips'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCarSelection(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Change Vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddVehicleDialog() async {
    final registrationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add New Vehicle',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the vehicle registration number to add it to your account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: registrationController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Registration Number',
                        hintText: 'e.g. T1234AB',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.dividerColor,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a registration number';
                        }
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          setState(() => isLoading = true);
                          try {
                            await _addVehicle(registrationController.text.trim());
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ADD VEHICLE',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addVehicle(String registration) async {
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    try {
      await carProvider.addCar(registration);
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
        // Reload the view to show the new car
        await carProvider.loadCars();
      }
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

  void _showCarSelection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const CarSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final carProvider = Provider.of<CarProvider>(context);
    
    // Show empty state if no cars are available
    if (carProvider.cars.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    // Animated illustration
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            Icons.directions_car_filled_outlined,
                            size: 100,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Title
                    Text(
                      'No Vehicles Yet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      'Get started by adding your first vehicle to track your finances and manage your trips efficiently.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    // Action button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: ElevatedButton(
                        onPressed: _showAddVehicleDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Add Your First Vehicle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Consumer<CarProvider>(
          builder: (context, carProvider, _) {
            final car = carProvider.currentCar;
            final hasCar = car != null;
            
            return InkWell(
              onTap: hasCar ? () => _showVehicleDetails(context, car.registration) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasCar ? 'Active Vehicle' : 'No vehicle selected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasCar ? car.registration : 'Tap to select',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    if (hasCar) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          // Add Sync Button
          const SyncButton(),
          PopupMenuButton<MenuAction>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, size: 20),
            ),
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  if (shouldLogout && context.mounted) {
                    context.read<AuthBloc>().add(const AuthEventLogout());
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[400]),
                    const SizedBox(width: 12),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Text(
                    _selectedDay != null 
                        ? DateFormat('EEEE, MMMM d, y').format(_selectedDay!)
                        : 'Select a date',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Calendar Card
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          weekendTextStyle: TextStyle(
                            color: isDark ? Colors.blue[200] : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                          todayDecoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          titleTextStyle: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: theme.colorScheme.primary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.blue[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          final normalizedDay = DateTime(
                            selectedDay.year, 
                            selectedDay.month, 
                            selectedDay.day
                          );
                          
                          if (!isSameDay(_selectedDay, normalizedDay)) {
                            setState(() {
                              _selectedDay = normalizedDay;
                              _focusedDay = focusedDay;
                              _isLoading = true;
                            });
                            _loadFinancialData();
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content
            if (_selectedDay != null) ...[
              _isLoading
                  ? const Expanded(
                      child: Center(
                        child: LoadingIndicator(size: LoadingIndicatorSize.large),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Financial Overview Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFinancialCard(
                                    context: context,
                                    title: 'Income',
                                    amount: _totalIncome,
                                    icon: Icons.arrow_downward_rounded,
                                    color: Colors.green,
                                    onTap: () => _showFinancialDetails(true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFinancialCard(
                                    context: context,
                                    title: 'Expense',
                                    amount: _totalExpense,
                                    icon: Icons.arrow_upward_rounded,
                                    color: Colors.red,
                                    onTap: () => _showFinancialDetails(false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFinancialCard(
                              context: context,
                              title: 'Balance',
                              amount: _balance,
                              icon: _balance >= 0 ? Icons.account_balance_wallet : Icons.warning_rounded,
                              color: _balance >= 0 ? Colors.blue : Colors.orange,
                              isBalance: true,
                            ),
                            const SizedBox(height: 24),
                            
                            // Quick Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCompactActionButton(
                                  context: context,
                                  icon: Icons.add_circle_outline,
                                  label: 'Add Income',
                                  color: Colors.green[700]!,
                                  onTap: _showAddIncomeDialog,
                                ),
                                _buildCompactActionButton(
                                  context: context,
                                  icon: Icons.remove_circle_outline,
                                  label: 'Add Expense',
                                  color: Colors.red[700]!,
                                  onTap: _showAddExpenseDialog,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ] else ...[
              // Empty State
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 72,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a date to begin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a date to view or add financial entries',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildFinancialCard({
    required BuildContext context,
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
    bool isBalance = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    final formattedAmount = NumberFormat.currency(
      symbol: 'Ar ',
      decimalDigits: 0,
    ).format(amount);
    
    // Define gradient colors based on card type
    final gradientColors = isBalance
        ? [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ]
        : [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[850]! : Colors.grey[50]!,
          ];

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBalance ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          if (!isDark && !isBalance)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: isBalance ? color : textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: isBalance ? 22 : 20,
              fontWeight: FontWeight.w700,
              color: isBalance ? color : textColor,
              letterSpacing: -0.5,
            ),
          ),
          if (isBalance) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    amount >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amount >= 0 ? 'In Profit' : 'In Deficit',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap with InkWell if onTap is provided
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: cardContent,
        ),
      );
    } else {
      cardContent = Material(color: Colors.transparent, child: cardContent);
    }
    
    // Return the card with proper sizing
    return isBalance 
        ? cardContent 
        : Expanded(child: cardContent);
  }  

  Widget _buildCompactActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
