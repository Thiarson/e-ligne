import 'package:flutter/material.dart';

class FinancialCard extends StatelessWidget {
  final String title;
  final int amount;
  final Color color;
  final VoidCallback? onTap;
  final IconData? icon;

  const FinancialCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (backgroundColor ?? Colors.white).withOpacity(0.9),
                  backgroundColor ?? Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (icon != null) Icon(icon, size: 18, color: color),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${amount.toStringAsFixed(0)} Ar',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// For backward compatibility
Widget buildFinancialCard(String title, int amount, Color color, VoidCallback? onTap) {
  return FinancialCard(
    title: title,
    amount: amount,
    color: color,
    onTap: onTap,
    icon: title == 'Income' 
        ? Icons.arrow_downward_rounded 
        : title == 'Expense' 
          ? Icons.arrow_upward_rounded 
          : Icons.account_balance_wallet_rounded,
  );
}
