import 'package:ligne/core/constants/db_fields.dart';
import 'package:ligne/data/repositories/expense_repository.dart';
import 'package:ligne/data/models/local/financial_entry_model.dart';
import 'package:ligne/data/repositories/income_repository.dart';
import 'package:ligne/utils/helpers/db_manager.dart';

class AdminService {
  final IncomeRepository _incomeRepository = IncomeRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  
  static const String _carryoverDescription = 'Balance Carryover';
  static const String _carryoverSource = 'Previous Day';
  
  AdminService() {
    DatabaseManager().ensureDbIsOpen();
  }

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
  
  Future<void> _deleteExistingCarryover(DateTime date) async {
    try {
      // Normalize the date to remove time component
      final dateNormalized = DateTime(date.year, date.month, date.day);
      
      // Get all incomes and expenses for the normalized date
      final incomes = await _incomeRepository.select(date: dateNormalized);
      final expenses = await _expenseRepository.select(date: dateNormalized);
      
      // Delete matching income carryovers
      for (final income in incomes) {
        if (income[incomeDescriptionColumn] == _carryoverDescription && 
            income[incomeSourceColumn] == _carryoverSource) {
          await _incomeRepository.delete(incomeId: income[incomeIdColumn] as int);
        }
      }
      
      // Delete matching expense carryovers
      for (final expense in expenses) {
        if (expense[expenseDescriptionColumn] == _carryoverDescription && 
            expense[expenseSourceColumn] == _carryoverSource) {
          await _expenseRepository.delete(expenseId: expense[expenseIdColum] as int);
        }
      }      
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> processBalanceCarryover(DateTime selectedDate) async {
    try {
      // Normalize dates to compare only the date part (without time)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDateNormalized = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      // Only process carryover for today or past dates
      if (selectedDateNormalized.isAfter(today)) {
        return;
      }
      
      // For today, we want to use yesterday's balance
      final previousDay = selectedDateNormalized.subtract(const Duration(days: 1));
      final previousBalance = await getBalance(previousDay);
      
      // No need to do anything if balance is zero
      if (previousBalance == 0) {
        return;
      }
      
      // Delete any existing carryover for the selected date
      await _deleteExistingCarryover(selectedDateNormalized);
      
      // Create appropriate carryover entry
      if (previousBalance > 0) {
        // Add to income
        final entry = IncomeModel(
          id: 0, // Will be set by the database
          description: _carryoverDescription,
          amount: previousBalance,
          date: selectedDateNormalized,
          source: _carryoverSource,
        );
        await addIncomeEntry(entry);
      } else {
        // Add to expenses (convert to positive amount)
        final entry = ExpenseModel(
          id: 0, // Will be set by the database
          description: _carryoverDescription,
          amount: -previousBalance, // Convert to positive
          date: selectedDateNormalized,
          source: _carryoverSource,
        );
        await addExpenseEntry(entry);
      }      
    } catch (e) {
      rethrow;
    }
  }

  deleteIncomeEntry(entry) {}

  deleteExpenseEntry(entry) {}
}
