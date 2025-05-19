import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:ligne/core/enums/menu_action.dart';
import 'package:ligne/data/models/local/financial_entry.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/widgets/financial_card.dart';
import 'package:ligne/utils/dialogs/logout_dialog.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<FinancialEntryModel>> _financialEntries = {};
  final _uuid = const Uuid();

  List<FinancialEntryModel> _getFinancialEntriesForDay(DateTime date) {
    return _financialEntries[DateTime(date.year, date.month, date.day)] ?? [];
  }

  double _getTotalIncome(DateTime date) {
    return _getFinancialEntriesForDay(date)
        .whereType<IncomeModel>()
        .fold(0, (sum, income) => sum + income.amount);
  }

  double _getTotalExpense(DateTime date) {
    return _getFinancialEntriesForDay(date)
        .whereType<ExpenseModel>()
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double _getBalance(DateTime date) {
    return _getTotalIncome(date) - _getTotalExpense(date);
  }

  void _processBalanceCarryover(DateTime date) {
    final previousDay = DateTime(date.year, date.month, date.day - 1);
    final previousBalance = _getBalance(previousDay);
    
    if (previousBalance != 0) {
      final day = DateTime(date.year, date.month, date.day);
      final existingEntries = _getFinancialEntriesForDay(day);
      
      // Check if balance carryover already exists for this day
      final hasCarryover = existingEntries.any((entry) => 
        entry.description == 'Balance Carryover' && 
        entry.source == 'Previous Day'
      );
      
      if (!hasCarryover) {
        final entry = previousBalance > 0
            ? IncomeModel(
                id: _uuid.v4(),
                description: 'Balance Carryover',
                amount: previousBalance,
                date: day,
                source: 'Previous Day',
              )
            : ExpenseModel(
                id: _uuid.v4(),
                description: 'Balance Carryover',
                amount: -previousBalance,
                date: day,
                source: 'Previous Day',
              );
        
        _addFinancialEntry(entry);
      }
    }
  }

  void _addFinancialEntry(FinancialEntryModel entry) {
    final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
    if (_financialEntries[day] == null) {
      _financialEntries[day] = [];
    }
    _financialEntries[day]!.add(entry);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _processBalanceCarryover(_selectedDay!);
  }

  Future<void> _showAddIncomeDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final sourceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(hintText: 'Source'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && _selectedDay != null) {
      final amount = double.tryParse(amountController.text) ?? 0;
      final entry = IncomeModel(
        id: _uuid.v4(),
        description: descriptionController.text,
        amount: amount,
        date: _selectedDay!,
        source: sourceController.text,
      );
      _addFinancialEntry(entry);
    }
  }

  Future<void> _showAddExpenseDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final sourceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(hintText: 'Source'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && _selectedDay != null) {
      final amount = double.tryParse(amountController.text) ?? 0;
      final entry = ExpenseModel(
        id: _uuid.v4(),
        description: descriptionController.text,
        amount: amount,
        date: _selectedDay!,
        source: sourceController.text,
      );
      _addFinancialEntry(entry);
    }
  }

  void _showFinancialDetails(bool isIncome) {
    if (_selectedDay == null) return;

    final entries = _getFinancialEntriesForDay(_selectedDay!)
        .where((entry) => isIncome ? entry is IncomeModel : entry is ExpenseModel)
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
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
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  title: Text(entry.description),
                  subtitle: Text(entry.source),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${entry.amount.toStringAsFixed(0)} Ar',
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
      ),
    );
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
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _processBalanceCarryover(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          if (_selectedDay != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: buildFinancialCard(
                    'Income',
                    _getTotalIncome(_selectedDay!),
                    Colors.green,
                    () => _showFinancialDetails(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildFinancialCard(
                    'Expense',
                    _getTotalExpense(_selectedDay!),
                    Colors.red,
                    () => _showFinancialDetails(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            buildFinancialCard(
              'Balance',
              _getBalance(_selectedDay!),
              Colors.blue,
              null,
            ),
          ],
        ],
      ),
    );
  }
}
