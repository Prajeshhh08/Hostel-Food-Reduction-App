import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/meal_edit_data.dart';

class MealEditorFoodRow extends StatelessWidget {
  final MealItemEditData item;
  final ValueChanged<int> onPortionChanged;
  final VoidCallback? onRemove;
  final bool readOnly;

  const MealEditorFoodRow({
    super.key,
    required this.item,
    required this.onPortionChanged,
    this.onRemove,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.hasResponses
              ? Colors.green.shade200
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (item.hasResponses) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Has ${item.responseCount} student response${item.responseCount == 1 ? "" : "s"}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Portion input
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: item.portionGrams > 0
                      ? item.portionGrams.toString()
                      : '',
                  enabled: !readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Portion',
                    suffixText: 'g',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final portion = int.tryParse(val.trim()) ?? 0;
                    onPortionChanged(portion);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
              if (!readOnly)
                item.hasResponses
                    ? Tooltip(
                        message:
                            'This food item already has student responses and cannot be removed from this meal.',
                        child: IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: Colors.grey.shade400),
                          onPressed: null,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFDC2626)),
                        tooltip: 'Remove food item',
                        onPressed: onRemove,
                      ),
            ],
          ),
        ],
      ),
    );
  }
}
