import 'package:flutter/material.dart';
import '../models/course_year_demand.dart';

class CourseYearDemandCard extends StatelessWidget {
  final CourseYearDemand demand;
  final bool showScopeBadge;

  const CourseYearDemandCard({
    super.key,
    required this.demand,
    this.showScopeBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = demand.totalResponses;
    final wantRatio = total > 0 ? demand.wantsCount / total : 0.0;

    final scopeParts = <String>[];
    if (demand.courseCode?.isNotEmpty == true) {
      scopeParts.add(demand.courseCode!);
    }
    if (demand.studyYearLabel?.isNotEmpty == true) {
      scopeParts.add(demand.studyYearLabel!);
    }
    final scopeLabel = scopeParts.join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Name & Scope Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    demand.foodName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (showScopeBadge && scopeLabel.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      scopeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Counts Grid
            Row(
              children: [
                // Wants
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.thumb_up_alt_rounded,
                              size: 14,
                              color: Color(0xFF15803D),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Want',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${demand.wantsCount}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Don't Want
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.thumb_down_alt_rounded,
                              size: 14,
                              color: Color(0xFFB91C1C),
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Don't Want",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${demand.doesntWantCount}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Total
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 14,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ratio Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: total == 0
                    ? Container(color: Colors.grey.shade200)
                    : Row(
                        children: [
                          if (demand.wantsCount > 0)
                            Expanded(
                              flex: demand.wantsCount,
                              child: Container(color: const Color(0xFF16A34A)),
                            ),
                          if (demand.doesntWantCount > 0)
                            Expanded(
                              flex: demand.doesntWantCount,
                              child: Container(color: const Color(0xFFDC2626)),
                            ),
                        ],
                      ),
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(wantRatio * 100).toStringAsFixed(0)}% Want',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  Text(
                    '${((1 - wantRatio) * 100).toStringAsFixed(0)}% Don\'t Want',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
