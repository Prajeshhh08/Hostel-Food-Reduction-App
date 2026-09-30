import 'package:flutter/material.dart';

class FoodSelectionCard extends StatelessWidget {
  final String foodName;
  final int portionGrams;
  final bool? wantsFood; // null = unselected, true = WANT, false = DON'T WANT
  final ValueChanged<bool>? onSelectionChanged;
  final bool enabled;

  const FoodSelectionCard({
    super.key,
    required this.foodName,
    this.portionGrams = 0,
    required this.wantsFood,
    this.onSelectionChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSelectedWant = wantsFood == true;
    final isSelectedDontWant = wantsFood == false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: wantsFood != null
              ? (isSelectedWant ? Colors.green.shade400 : Colors.red.shade300)
              : Colors.grey.shade200,
          width: wantsFood != null ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    foodName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (portionGrams > 0)
                  Text(
                    '${portionGrams}g',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // WANT Button
                Expanded(
                  child: Opacity(
                    opacity: enabled ? 1.0 : (isSelectedWant ? 1.0 : 0.4),
                    child: InkWell(
                      onTap: enabled && onSelectionChanged != null
                          ? () => onSelectionChanged!(true)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelectedWant
                              ? const Color(0xFF15803D)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelectedWant
                               ? const Color(0xFF15803D)
                                : Colors.green.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelectedWant) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              'WANT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelectedWant
                                    ? Colors.white
                                    : const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // DON'T WANT Button
                Expanded(
                  child: Opacity(
                    opacity: enabled ? 1.0 : (isSelectedDontWant ? 1.0 : 0.4),
                    child: InkWell(
                      onTap: enabled && onSelectionChanged != null
                          ? () => onSelectionChanged!(false)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelectedDontWant
                              ? const Color(0xFFDC2626)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelectedDontWant
                                ? const Color(0xFFDC2626)
                                : Colors.red.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelectedDontWant) ...[
                              const Icon(
                                Icons.cancel_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              "DON'T WANT",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelectedDontWant
                                    ? Colors.white
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
