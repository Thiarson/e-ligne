import 'package:flutter/material.dart';
import 'package:ligne/core/enums/menu_action.dart';

Future<bool> showAddFinancialDialog(
  BuildContext context,
  TextEditingController descriptionController,
  TextEditingController amountController,
  TextEditingController sourceController,
  FinancialType type,
) async {
  final financialType = type == FinancialType.income
      ? 'Income'
      : 'Expense';
  
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add $financialType'),
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

  return result ?? false;
}
