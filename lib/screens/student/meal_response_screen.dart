import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../models/food_response.dart';
import '../../models/meal_item.dart';
import '../../providers/meal_provider.dart';
import '../../providers/response_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/food_selection_card.dart';
import '../../widgets/loading_view.dart';

class MealResponseScreen extends ConsumerStatefulWidget {
  final int mealId;

  const MealResponseScreen({super.key, required this.mealId});

  @override
  ConsumerState<MealResponseScreen> createState() => _MealResponseScreenState();
}

class _MealResponseScreenState extends ConsumerState<MealResponseScreen> {
  // Local state map: meal_item_id -> wants_food (true/false)
  final Map<int, bool> _selections = {};
  bool _initialized = false;

  void _initSelections(List<MealItem> items, List<FoodResponse> existingResponses) {
    if (_initialized) return;

    for (var response in existingResponses) {
      _selections[response.mealItemId] = response.wantsFood;
    }
    _initialized = true;
  }

  Future<void> _handleSubmit() async {
    if (_selections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preference for at least one item.'),
        ),
      );
      return;
    }

    try {
      await ref.read(saveResponsesNotifierProvider.notifier).saveResponses(
            mealId: widget.mealId,
            mealItemResponses: _selections,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✓ Response saved successfully'),
              ],
            ),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));
    final responsesAsync = ref.watch(userMealResponsesProvider(widget.mealId));
    final saveState = ref.watch(saveResponsesNotifierProvider);
    final isSaving = saveState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Selection'),
      ),
      body: mealAsync.when(
        data: (meal) {
          if (meal == null) {
            return const ErrorView(message: 'Meal not found');
          }

          final isClosed = meal.isDeadlinePassed;

          return responsesAsync.when(
            data: (responses) {
              _initSelections(meal.mealItems, responses);
              final hasExisting = responses.isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isClosed
                              ? [
                                  Colors.blueGrey.shade700,
                                  Colors.blueGrey.shade900,
                                ]
                              : [
                                  const Color(0xFF15803D),
                                  Colors.green.shade800,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                meal.displayIcon,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                meal.displayName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              if (isClosed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade900
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'CLOSED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meal.menuName.isNotEmpty
                                ? meal.menuName
                                : "Menu",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Date: ${meal.mealDate}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                          if (hasExisting) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '✓ You have submitted preferences for this meal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deadline info banner
                    if (isClosed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Responses for this meal are closed (deadline passed on ${meal.formatDeadlineKolkata()}). Your selections are read-only.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (meal.responseDeadline != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 18, color: Color(0xFF92400E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Response deadline: ${meal.formatDeadlineKolkata()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    Text(
                      isClosed
                          ? 'Your Recorded Choices:'
                          : 'Select what you want to eat:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (meal.mealItems.isEmpty) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No food items listed for this meal.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: meal.mealItems.length,
                        itemBuilder: (context, index) {
                          final item = meal.mealItems[index];
                          final foodName = item.foodItem?.name ?? 'Food Item';
                          final wantsFood = _selections[item.id];

                          return FoodSelectionCard(
                            foodName: foodName,
                            portionGrams: item.portionGrams,
                            wantsFood: wantsFood,
                            enabled: !isClosed,
                            onSelectionChanged: isClosed
                                ? null
                                : (value) {
                                    setState(() {
                                      _selections[item.id] = value;
                                    });
                                  },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit / Locked Button
                      if (isClosed)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.lock_rounded, size: 18),
                            label: const Text('Responses Closed'),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: isSaving ? null : _handleSubmit,
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(hasExisting
                                  ? 'Update Response'
                                  : 'Submit Response'),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              );
            },
            loading: () => const LoadingView(
              message: 'Loading your meal choices...',
            ),
            error: (err, s) => ErrorView(
              message: ErrorHandler.getFriendlyErrorMessage(err),
              onRetry: () => ref.invalidate(userMealResponsesProvider(widget.mealId)),
            ),
          );
        },
        loading: () => const LoadingView(message: 'Loading meal details...'),
        error: (err, s) => ErrorView(
          message: ErrorHandler.getFriendlyErrorMessage(err),
          onRetry: () => ref.invalidate(mealDetailProvider(widget.mealId)),
        ),
      ),
    );
  }
}
