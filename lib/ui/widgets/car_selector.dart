import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ligne/core/services/admin/car_provider.dart';
import 'package:ligne/ui/views/admin/car_selection_screen.dart';

class CarSelector extends StatelessWidget {
  final bool showLabel;
  final bool showIcon;
  final bool showChevron;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onCarSelected;

  const CarSelector({
    Key? key,
    this.showLabel = true,
    this.showIcon = true,
    this.showChevron = true,
    this.padding,
    this.onCarSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, provider, _) {
        final hasCars = provider.cars.isNotEmpty;
        final currentCar = provider.currentCar;
        final carCount = provider.cars.length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToCarSelection(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showLabel) ...[
                          Text(
                            'Current Vehicle',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentCar?.registration ?? 'No vehicle selected',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasCars && carCount > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$carCount',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasCars && currentCar != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Tap to change vehicle',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Theme.of(context).hintColor.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
  Future<void> _navigateToCarSelection(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CarSelectionScreen(),
      ),
    );
    
    if (result == true && onCarSelected != null) {
      onCarSelected!();
    }
  }
}
