import 'package:flutter/material.dart';

Future<bool> showAddFinancialDialog(
  BuildContext context,
  TextEditingController descriptionController,
  TextEditingController amountController,
  TextEditingController sourceController,
) async {
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

  return result ?? false;
}
