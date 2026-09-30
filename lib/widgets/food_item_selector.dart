import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/error_handler.dart';
import '../models/food_item.dart';
import '../providers/menu_provider.dart';
import 'error_view.dart';
import 'loading_view.dart';

class FoodItemSelectorSheet extends ConsumerStatefulWidget {
  final Set<int> existingFoodItemIds;
  final ValueChanged<FoodItem> onFoodSelected;

  const FoodItemSelectorSheet({
    super.key,
    required this.existingFoodItemIds,
    required this.onFoodSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Set<int> existingFoodItemIds,
    required ValueChanged<FoodItem> onFoodSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FoodItemSelectorSheet(
        existingFoodItemIds: existingFoodItemIds,
        onFoodSelected: onFoodSelected,
      ),
    );
  }

  @override
  ConsumerState<FoodItemSelectorSheet> createState() =>
      _FoodItemSelectorSheetState();
}

class _FoodItemSelectorSheetState extends ConsumerState<FoodItemSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final foodItemsAsync = ref.watch(adminFoodItemsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Food Item',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search food items...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: foodItemsAsync.when(
                  data: (items) {
                    final filtered = items.where((item) {
                      if (_searchQuery.isNotEmpty &&
                          !item.name.toLowerCase().contains(_searchQuery)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No food items found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final food = filtered[index];
                        final isAlreadyAdded =
                            widget.existingFoodItemIds.contains(food.id);

                        return ListTile(
                          title: Text(
                            food.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isAlreadyAdded
                                  ? Colors.grey
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            'Default portion: ${food.defaultPortionGrams > 0 ? "${food.defaultPortionGrams}g" : "Not set"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: isAlreadyAdded
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Added',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : FilledButton.tonal(
                                  onPressed: () {
                                    widget.onFoodSelected(food);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Add'),
                                ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingView(
                      message: 'Loading food catalogue...'),
                  error: (err, _) => ErrorView(
                    message: ErrorHandler.getFriendlyErrorMessage(err),
                    onRetry: () => ref.invalidate(adminFoodItemsProvider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
