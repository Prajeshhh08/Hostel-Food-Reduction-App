import 'package:flutter/material.dart';
import '../models/food_prediction.dart';

class FoodPredictionCard extends StatefulWidget {
  final FoodPrediction prediction;

  const FoodPredictionCard({
    super.key,
    required this.prediction,
  });

  @override
  State<FoodPredictionCard> createState() => _FoodPredictionCardState();
}

class _FoodPredictionCardState extends State<FoodPredictionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final hasHistory = p.hasHistoricalData;
    final noShowPercent = (p.historicalNoShowRate * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Name & Portion info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.foodName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (p.portionGrams > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Serving: ${p.portionGrams.toInt()} g',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Demand Context
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Students requesting this',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.confirmedWantCount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected demand',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.expectedDemand.toStringAsFixed(1)} portions',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Highlighted Recommendation Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.soup_kitchen_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECOMMENDED PREPARATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${p.recommendedPortions} portions',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14532D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '≈ ${p.formattedQuantity}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Historical Adjustment Note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasHistory
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    hasHistory
                        ? Icons.history_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: hasHistory
                        ? const Color(0xFFB45309)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasHistory
                          ? 'Historical attendance adjustment: $noShowPercent%'
                          : 'No historical attendance data yet. Recommendation based on current demand.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasHistory
                            ? const Color(0xFF92400E)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expandable Calculation Explanation
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Hide explanation' : 'How this was calculated',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculation Breakdown:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Current student demand: ${p.confirmedWantCount} requested ${p.foodName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    if (hasHistory)
                      Text(
                        '• Historical no-show adjustment: $noShowPercent% based on past records\n'
                        '  Expected = ${p.confirmedWantCount} × (1 − ${p.historicalNoShowRate}) = ${p.expectedDemand.toStringAsFixed(2)} portions',
                        style: const TextStyle(fontSize: 12),
                      )
                    else
                      const Text(
                        '• No previous attendance history is available yet, so no historical adjustment was applied.',
                        style: TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      '• Recommended: ceil(${p.expectedDemand.toStringAsFixed(2)}) = ${p.recommendedPortions} portions (${p.formattedQuantity})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
