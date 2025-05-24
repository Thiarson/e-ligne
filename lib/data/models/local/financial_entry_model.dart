class FinancialEntryModel {
  final int id;
  final String description;
  final int amount;
  final DateTime date;
  final String source;

  FinancialEntryModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.source,
  });
}

class IncomeModel extends FinancialEntryModel {
  IncomeModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    required super.source,
  });
}

class ExpenseModel extends FinancialEntryModel {
  ExpenseModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    required super.source,
  });
} 
