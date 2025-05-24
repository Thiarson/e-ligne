import 'package:uuid/uuid.dart';
import 'package:ligne/data/models/local/financial_entry_model.dart';

class AdminService {
  final Map<DateTime, List<FinancialEntryModel>> _financialEntries = {};
  final _uuid = const Uuid();

  List<FinancialEntryModel> getFinancialEntriesForDay(DateTime date) {
    return _financialEntries[DateTime(date.year, date.month, date.day)] ?? [];
  }

  double getTotalIncome(DateTime date) {
    return getFinancialEntriesForDay(date)
        .whereType<IncomeModel>()
        .fold(0, (sum, income) => sum + income.amount);
  }

  double getTotalExpense(DateTime date) {
    return getFinancialEntriesForDay(date)
        .whereType<ExpenseModel>()
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double getBalance(DateTime date) {
    return getTotalIncome(date) - getTotalExpense(date);
  }

  void processBalanceCarryover(DateTime date) {
    final previousDay = DateTime(date.year, date.month, date.day - 1);
    final previousBalance = getBalance(previousDay);
    
    if (previousBalance != 0) {
      final day = DateTime(date.year, date.month, date.day);
      final existingEntries = getFinancialEntriesForDay(day);
      
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
        
        addFinancialEntry(entry);
      }
    }
  }

  void addFinancialEntry(FinancialEntryModel entry) {
    final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
    if (_financialEntries[day] == null) {
      _financialEntries[day] = [];
    }
    _financialEntries[day]!.add(entry);
  }
}
