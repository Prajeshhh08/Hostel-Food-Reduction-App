import 'package:flutter/material.dart';
import '../models/meal.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final String actionLabel;
  final bool showDeadline;
  final Widget? trailingBadge;

  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.actionLabel = 'View Food',
    this.showDeadline = true,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    // Generate food items summary if available
    String foodSummary = meal.menuName;
    if (foodSummary.isEmpty && meal.mealItems.isNotEmpty) {
      foodSummary = meal.mealItems
          .map((item) => item.foodItem?.name ?? 'Item')
          .join(' + ');
    }

    final isClosed = meal.isDeadlinePassed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  meal.displayIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailingBadge != null) ...[
                  trailingBadge!,
                  const SizedBox(width: 6),
                ],
                if (meal.mealItems.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isClosed
                          ? Colors.grey.shade100
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isClosed
                            ? Colors.grey.shade300
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      '${meal.mealItems.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isClosed
                            ? Colors.grey.shade600
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              foodSummary.isNotEmpty ? foodSummary : 'No items listed yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (showDeadline && meal.responseDeadline != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    isClosed
                        ? Icons.lock_clock_outlined
                        : Icons.access_time_rounded,
                    size: 14,
                    color: isClosed
                        ? Colors.grey.shade500
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isClosed
                        ? 'Responses closed (${meal.formatDeadlineKolkata()})'
                        : 'Deadline: ${meal.formatDeadlineKolkata()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isClosed
                          ? Colors.grey.shade500
                          : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isClosed
                  ? OutlinedButton(
                      onPressed: onTap,
                      child: Text(actionLabel),
                    )
                  : FilledButton.tonal(
                      onPressed: onTap,
                      child: Text(actionLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
