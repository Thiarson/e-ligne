import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/core/enums/menu_action.dart';
import 'package:ligne/core/services/admin/admin_service.dart';
import 'package:ligne/data/models/local/financial_entry_model.dart';
import 'package:ligne/data/repositories/income_repository.dart';
import 'package:ligne/data/repositories/expense_repository.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/widgets/financial_card.dart';
import 'package:ligne/utils/helpers/db_manager.dart';
import 'package:ligne/utils/dialogs/logout_dialog.dart';
import 'package:ligne/utils/dialogs/add_financial_dialog.dart';

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
      _loadFinancialData();
    });
  }

  Future<void> _loadFinancialData() async {
    if (_selectedDay == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Process balance carryover first
      await _adminService.processBalanceCarryover(_selectedDay!);
      
      // Then get the updated financial data
      final totalIncome = await _adminService.getTotalIncome(_selectedDay!);
      final totalExpense = await _adminService.getTotalExpense(_selectedDay!);
      final balance = await _adminService.getBalance(_selectedDay!);
      
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
          description: descriptionController.text,
          amount: amount,
          date: _selectedDay!,
          source: sourceController.text,
        );
        
        await _adminService.addIncomeEntry(entry);
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
          description: descriptionController.text,
          amount: amount,
          date: _selectedDay!,
          source: sourceController.text,
        );
        
        await _adminService.addExpenseEntry(entry);
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

    try {
      setState(() => _isLoading = true);
      
      List<Map<String, dynamic>> entries;
      if (isIncome) {
        final incomeRepo = IncomeRepository();
        await DatabaseManager().ensureDbIsOpen();
        entries = await incomeRepo.select(date: _selectedDay!);
      } else {
        final expenseRepo = ExpenseRepository();
        await DatabaseManager().ensureDbIsOpen();
        entries = await expenseRepo.select(date: _selectedDay!);
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  title: Text(isIncome ? 'Income Details' : 'Expense Details'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: isIncome ? _showAddIncomeDialog : _showAddExpenseDialog,
                    ),
                  ],
                ),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No entries found')),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: entries.length,
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
                        
                        return ListTile(
                          title: Text(description),
                          subtitle: Text(source),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${amount.toStringAsFixed(0)} Ar',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Administration'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  if (shouldLogout && context.mounted) {
                    context.read<AuthBloc>().add(const AuthEventLogout());
                  }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              // Normalize the selected day to remove time component
              final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
              
              if (!isSameDay(_selectedDay, normalizedDay)) {
                setState(() {
                  _selectedDay = normalizedDay;
                  _focusedDay = focusedDay;
                  _isLoading = true; // Show loading state
                });
                
                // Load financial data with the normalized date
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
          ),
          if (_selectedDay != null) ...[
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: buildFinancialCard(
                              'Income',
                              _totalIncome,
                              Colors.green,
                              () => _showFinancialDetails(true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: buildFinancialCard(
                              'Expense',
                              _totalExpense,
                              Colors.red,
                              () => _showFinancialDetails(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      buildFinancialCard(
                        'Balance',
                        _balance,
                        _balance >= 0 ? Colors.blue : Colors.orange,
                        null,
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}
