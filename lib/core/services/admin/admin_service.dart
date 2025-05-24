import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/data/repositories/expense_repository.dart';
import 'package:ligne/data/models/local/financial_entry_model.dart';
import 'package:ligne/data/repositories/income_repository.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class AdminService {
  // final Map<DateTime, List<FinancialEntryModel>> _financialEntries = {};

  // List<FinancialEntryModel> getFinancialEntriesForDay(DateTime date) {
  //   return _financialEntries[DateTime(date.year, date.month, date.day)] ?? [];
  // }

  // void processBalanceCarryover(DateTime date) {
  //   final previousDay = DateTime(date.year, date.month, date.day - 1);
  //   final previousBalance = getBalance(previousDay);
    
  //   if (previousBalance != 0) {
  //     final day = DateTime(date.year, date.month, date.day);
  //     final existingEntries = getFinancialEntriesForDay(day);
      
  //     // Check if balance carryover already exists for this day
  //     final hasCarryover = existingEntries.any((entry) => 
  //       entry.description == 'Balance Carryover' && 
  //       entry.source == 'Previous Day'
  //     );
      
  //     if (!hasCarryover) {
  //       final entry = previousBalance > 0
  //           ? IncomeModel(
  //               id: int.parse(_uuid.v4()),
  //               description: 'Balance Carryover',
  //               amount: previousBalance,
  //               date: day,
  //               source: 'Previous Day',
  //             )
  //           : ExpenseModel(
  //               id: int.parse(_uuid.v4()),
  //               description: 'Balance Carryover',
  //               amount: -previousBalance,
  //               date: day,
  //               source: 'Previous Day',
  //             );
        
  //       addFinancialEntry(entry);
  //     }
  //   }
  // }

  Future<IncomeModel> addIncomeEntry(IncomeModel entry) async {
    await DatabaseManager().ensureDbIsOpen();
    final incomeRepository = IncomeRepository();

    final incomeId = await incomeRepository.insert(
      carId: 1, 
      description: entry.description, 
      amount: entry.amount, 
      source: entry.source,
      date: entry.date,
    );

    final newIncome = IncomeModel(
      id: incomeId,
      description: entry.description,
      amount: entry.amount,
      date: entry.date,
      source: entry.source,
    );

    return newIncome;
  }

  Future<ExpenseModel> addExpenseEntry(ExpenseModel entry) async {
    await DatabaseManager().ensureDbIsOpen();
    final expenseRepository = ExpenseRepository();

    final expenseId = await expenseRepository.insert(
      carId: 1, 
      description: entry.description, 
      amount: entry.amount, 
      source: entry.source,
      date: entry.date,
    );

    final newExpense = ExpenseModel(
      id: expenseId,
      description: entry.description,
      amount: entry.amount,
      date: entry.date,
      source: entry.source,
    );

    return newExpense;
  }

  Future<int> getTotalIncome(DateTime date) async {
    try {
      await DatabaseManager().ensureDbIsOpen();
      final incomeRepository = IncomeRepository();

      // Get all incomes for the selected day
      final incomes = await incomeRepository.select(date: date);
      
      // Calculate the total income
      final totalIncome = incomes.fold(0, (sum, income) {
        try {
          final amountStr = income[incomeAmountColumn] as String;
          return sum + (int.tryParse(amountStr) ?? 0);
        } catch (e) {
          return sum;
        }
      });

      return totalIncome;
    } catch (e) {
      return 0; // Return 0 in case of error
    }
  }

  Future<int> getTotalExpense(DateTime date) async {
    try {
      await DatabaseManager().ensureDbIsOpen();
      final expenseRepository = ExpenseRepository();

      // Get all expenses for the selected day
      final expenses = await expenseRepository.select(date: date);
      
      // Calculate the total expense
      final totalExpense = expenses.fold(0, (sum, expense) {
        try {
          final amountStr = expense[expenseAmountColumn] as String;
          return sum + (int.tryParse(amountStr) ?? 0);
        } catch (e) {
          return sum;
        }
      });

      return totalExpense;
    } catch (e) {
      return 0; // Return 0 in case of error
    }
  }

  Future<int> getBalance(DateTime date) async {
    try {
      final totalIncome = await getTotalIncome(date);
      final totalExpense = await getTotalExpense(date);
      return totalIncome - totalExpense;
    } catch (e) {
      return 0; // Return 0 in case of error
    }
  }
}
