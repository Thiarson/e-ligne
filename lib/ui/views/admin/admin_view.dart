import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ligne/core/enums/menu_action.dart';
import 'package:ligne/core/services/admin/admin_service.dart';
import 'package:ligne/data/models/local/financial_entry_model.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/widgets/financial_card.dart';
import 'package:ligne/utils/dialogs/logout_dialog.dart';
import 'package:ligne/utils/dialogs/add_financial_dialog.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  late final AdminService _adminService;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _uuid = const Uuid();
  
  @override
  void initState() {
    _adminService = AdminService();
    _selectedDay = DateTime.now();
    _adminService.processBalanceCarryover(_selectedDay!);
    
    super.initState();
  }

  Future<void> _showAddIncomeDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final sourceController = TextEditingController();

    final result = await showAddFinancialDialog(
      context, 
      descriptionController, 
      amountController, 
      sourceController
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
      _adminService.addFinancialEntry(entry);
      setState(() {});
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
      sourceController
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
      _adminService.addFinancialEntry(entry);
      setState(() {});
    }
  }

  void _showFinancialDetails(bool isIncome) {
    if (_selectedDay == null) return;

    final entries = _adminService.getFinancialEntriesForDay(_selectedDay!)
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
              _adminService.processBalanceCarryover(selectedDay);
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
                    _adminService.getTotalIncome(_selectedDay!),
                    Colors.green,
                    () => _showFinancialDetails(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildFinancialCard(
                    'Expense',
                    _adminService.getTotalExpense(_selectedDay!),
                    Colors.red,
                    () => _showFinancialDetails(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            buildFinancialCard(
              'Balance',
              _adminService.getBalance(_selectedDay!),
              Colors.blue,
              null,
            ),
          ],
        ],
      ),
    );
  }
}
