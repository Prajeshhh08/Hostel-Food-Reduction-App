import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../models/meal_edit_data.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/food_item_selector.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/meal_editor_food_row.dart';

class EditMealScreen extends ConsumerStatefulWidget {
  final int mealId;

  const EditMealScreen({super.key, required this.mealId});

  @override
  ConsumerState<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends ConsumerState<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuNameController = TextEditingController();

  DateTime? _responseDeadline;
  final List<MealItemEditData> _currentFoods = [];
  final List<int> _itemIdsToDelete = [];
  bool _initialized = false;

  @override
  void dispose() {
    _menuNameController.dispose();
    super.dispose();
  }

  void _initFormData(MealEditData data) {
    if (_initialized) return;
    _menuNameController.text = data.meal.menuName;
    _responseDeadline = data.meal.responseDeadline ??
        DateTime.now().add(const Duration(hours: 12));
    _currentFoods.clear();
    _currentFoods.addAll(data.items);
    _initialized = true;
  }

  String _formatDisplayDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDisplayDateTime(DateTime dt) {
    final kolkata = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = kolkata.hour;
    final minute = kolkata.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;

    return '${_formatDisplayDate(kolkata)} — $formattedHour:$minute $period';
  }

  Future<void> _pickDeadline(DateTime mealDate) async {
    if (_responseDeadline == null) return;
    final kolkataCurrent =
        _responseDeadline!.toUtc().add(const Duration(hours: 5, minutes: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: kolkataCurrent,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: mealDate,
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: kolkataCurrent.hour,
        minute: kolkataCurrent.minute,
      ),
    );

    if (pickedTime == null || !mounted) return;

    final localKolkataDt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final utcDt =
        localKolkataDt.subtract(const Duration(hours: 5, minutes: 30));

    setState(() {
      _responseDeadline = DateTime.utc(
        utcDt.year,
        utcDt.month,
        utcDt.day,
        utcDt.hour,
        utcDt.minute,
      );
    });
  }

  bool _isDeadlineValid(String mealDateStr) {
    if (_responseDeadline == null) return true;
    final parts = mealDateStr.split('-').map(int.parse).toList();
    final endOfMealDayUtc =
        DateTime.utc(parts[0], parts[1], parts[2], 18, 30);
    return _responseDeadline!.isBefore(endOfMealDayUtc);
  }

  Future<void> _handleSaveChanges(MealEditData data) async {
    if (data.isLocked) return;
    if (!_formKey.currentState!.validate()) return;

    if (_currentFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one food item is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentFoods.any((f) => f.portionGrams <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All food items must have a portion greater than 0g.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDeadlineValid(data.meal.mealDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response deadline must be before the meal date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(mealEditNotifierProvider.notifier).updateMeal(
            mealId: widget.mealId,
            menuName: _menuNameController.text.trim(),
            responseDeadline: _responseDeadline!,
            currentItems: _currentFoods,
            itemIdsToDelete: _itemIdsToDelete,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✓ Meal updated successfully'),
              ],
            ),
            backgroundColor: Color(0xFF15803D),
          ),
        );
        Navigator.pop(context);
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
    final editDataAsync = ref.watch(mealEditDataProvider(widget.mealId));
    final editState = ref.watch(mealEditNotifierProvider);
    final isSaving = editState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meal'),
      ),
      body: editDataAsync.when(
        data: (editData) {
          if (editData == null) {
            return const ErrorView(message: 'Meal not found');
          }

          _initFormData(editData);
          final meal = editData.meal;
          final isLocked = editData.isLocked;

          DateTime mealDateParsed;
          try {
            final parts = meal.mealDate.split('-').map(int.parse).toList();
            mealDateParsed =
                DateTime.utc(parts[0], parts[1], parts[2]);
          } catch (_) {
            mealDateParsed = DateTime.now();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lock / Historical Warning Banner
                  if (editData.hasWasteLog) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              color: Colors.blueGrey.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Meal completed • Post-meal waste has already been recorded. The menu is locked to maintain historical integrity.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (editData.isPastMeal) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded,
                              color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Past meal • This meal date has already passed. The menu is in read-only mode.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Meal Info Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          meal.displayIcon,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${meal.displayName.toUpperCase()} • ${meal.mealDate}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                meal.menuName.isNotEmpty
                                    ? meal.menuName
                                    : 'Menu',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Menu Name
                  const Text(
                    'Menu Display Name',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _menuNameController,
                    enabled: !isLocked,
                    decoration: InputDecoration(
                      hintText: 'e.g. Rice + Sambar + Curd',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a menu name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Response Deadline
                  const Text(
                    'Response Deadline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: isLocked
                        ? null
                        : () => _pickDeadline(mealDateParsed),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Color(0xFF92400E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _responseDeadline != null
                                  ? _formatDisplayDateTime(_responseDeadline!)
                                  : 'No deadline set',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                          if (!isLocked)
                            const Icon(Icons.edit_outlined,
                                size: 18, color: Color(0xFF92400E)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Food Items & Portion Sizes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Food Items & Portions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (!isLocked)
                        FilledButton.tonalIcon(
                          onPressed: () {
                            final existingIds = _currentFoods
                                .map((f) => f.foodItemId)
                                .toSet();
                            FoodItemSelectorSheet.show(
                              context,
                              existingFoodItemIds: existingIds,
                              onFoodSelected: (food) {
                                setState(() {
                                  _currentFoods.add(
                                    MealItemEditData(
                                      foodItemId: food.id,
                                      foodName: food.name,
                                      portionGrams:
                                          food.defaultPortionGrams > 0
                                              ? food.defaultPortionGrams
                                              : 100,
                                    ),
                                  );
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Food'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_currentFoods.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'No food items in this meal.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentFoods.length,
                      itemBuilder: (context, index) {
                        final item = _currentFoods[index];
                        return MealEditorFoodRow(
                          item: item,
                          readOnly: isLocked,
                          onPortionChanged: (portion) {
                            setState(() {
                              _currentFoods[index] =
                                  item.copyWith(portionGrams: portion);
                            });
                          },
                          onRemove: () {
                            setState(() {
                              if (item.id != null) {
                                _itemIdsToDelete.add(item.id!);
                              }
                              _currentFoods.removeAt(index);
                            });
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Actions
                  if (!isLocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () => _handleSaveChanges(editData),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () =>
            const LoadingView(message: 'Loading meal for editing...'),
        error: (err, _) => ErrorView(
          message: ErrorHandler.getFriendlyErrorMessage(err),
          onRetry: () => ref.invalidate(mealEditDataProvider(widget.mealId)),
        ),
      ),
    );
  }
}
