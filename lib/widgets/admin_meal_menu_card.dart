import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/meal.dart';

class AdminMealMenuCard extends StatelessWidget {
  final Meal meal;

  const AdminMealMenuCard({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayStr =
        "${nowKolkata.year.toString().padLeft(4, '0')}-${nowKolkata.month.toString().padLeft(2, '0')}-${nowKolkata.day.toString().padLeft(2, '0')}";
    final isPast = meal.mealDate.compareTo(todayStr) < 0;
    final isClosed = meal.isDeadlinePassed;

    Widget statusBadge;
    if (isPast) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'COMPLETED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      );
    } else if (isClosed) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Text(
          'CLOSED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Text(
          'OPEN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      );
    }

    String foodSummary = meal.menuName;
    if (foodSummary.isEmpty && meal.mealItems.isNotEmpty) {
      foodSummary = meal.mealItems
          .map((item) => item.foodItem?.name ?? 'Item')
          .join(' + ');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  meal.displayIcon,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  meal.displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                statusBadge,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              foodSummary.isNotEmpty ? foodSummary : 'No food items added',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (meal.mealItems.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: meal.mealItems.map((item) {
                  final name = item.foodItem?.name ?? 'Item';
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$name (${item.portionGrams}g)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (meal.responseDeadline != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: isClosed
                        ? Colors.grey.shade500
                        : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${meal.formatDeadlineKolkata()}',
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/admin/menu/${meal.id}/edit');
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(isPast ? 'View Menu' : 'Edit Menu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      context.push('/admin/meal/${meal.id}');
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('View Demand'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
