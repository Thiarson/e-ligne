import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/ui/widgets/loading/loading_indicator.dart';
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
import 'package:intl/intl.dart';

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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: isIncome ? Colors.green : Colors.red,
                                size: 28,
                              ),
                              onPressed: isIncome ? _showAddIncomeDialog : _showAddExpenseDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Total: ',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}${totalAmount.toStringAsFixed(0)} Ar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // List of entries
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        children: [
                          Icon(
                            isIncome ? Icons.account_balance_wallet : Icons.money_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${isIncome ? 'income' : 'expense'} recorded',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: isIncome ? _showAddIncomeDialog : _showAddExpenseDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isIncome ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Add ${isIncome ? 'Income' : 'Expense'}'),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) async {
                              try {
                                if (isIncome) {
                                  await _adminService.deleteIncomeEntry(entry['id']);
                                } else {
                                  await _adminService.deleteExpenseEntry(entry['id']);
                                }
                                setState(() {
                                  entries.removeAt(index);
                                  _loadFinancialData();
                                });
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${isIncome ? 'Income' : 'Expense'} deleted'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
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
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIncome ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  description,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  source,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Text(
                                  '${isIncome ? '+' : '-'}${amount.toStringAsFixed(0)} Ar',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () {
                                  // TODO: Implement edit functionality
                                },
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    // final today = DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Financial Overview',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<MenuAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  if (shouldLogout && context.mounted) {
                    context.read<AuthBloc>().add(const AuthEventLogout());
                  }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Logout'),
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
            // Date Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _selectedDay != null 
                    ? DateFormat('EEEE, MMMM d, y').format(_selectedDay!)
                    : 'Select a date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            
            // Calendar
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                calendarStyle: CalendarStyle(
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
                  weekendTextStyle: TextStyle(
                    color: isDark ? Colors.blue[200] : Colors.blue[700],
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  formatButtonShowsNext: false,
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
                  weekdayStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  weekendStyle: TextStyle(color: Colors.blue[300]),
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
            
            // Financial Summary
            if (_selectedDay != null) ...[
              const SizedBox(height: 8),
              _isLoading
                  ? const Expanded(
                      child: Center(
                        child: LoadingIndicator(size: LoadingIndicatorSize.medium),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Income & Expense Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: buildFinancialCard(
                                      'Income',
                                      _totalIncome,
                                      Colors.green,
                                      () => _showFinancialDetails(true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                              const SizedBox(height: 12),
                              // Balance Card
                              buildFinancialCard(
                                'Balance',
                                _balance,
                                _balance >= 0 ? Colors.blue : Colors.orange,
                                null,
                              ),
                              const SizedBox(height: 24),
                              // Quick Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    context,
                                    icon: Icons.add,
                                    label: 'Add Income',
                                    color: Colors.green,
                                    onTap: _showAddIncomeDialog,
                                  ),
                                  _buildActionButton(
                                    context,
                                    icon: Icons.remove,
                                    label: 'Add Expense',
                                    color: Colors.red,
                                    onTap: _showAddExpenseDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ] else ...[
              const Spacer(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a date to view financial data',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),    );
  }


  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
