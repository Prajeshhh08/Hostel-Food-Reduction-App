import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../models/meal_edit_data.dart';
import '../../providers/menu_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/food_item_selector.dart';
import '../../widgets/meal_editor_food_row.dart';

class CreateMealScreen extends ConsumerStatefulWidget {
  const CreateMealScreen({super.key});

  @override
  ConsumerState<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends ConsumerState<CreateMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuNameController = TextEditingController();

  late DateTime _selectedDate;
  String _selectedMealType = 'lunch';
  late DateTime _responseDeadline;
  final List<MealItemEditData> _selectedFoods = [];

  bool _isAutoMenuName = true;
  String? _duplicateWarning;

  @override
  void initState() {
    super.initState();
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    // Default to tomorrow
    _selectedDate = DateTime.utc(
        nowKolkata.year, nowKolkata.month, nowKolkata.day + 1);
    _responseDeadline = _computeDefaultDeadline(_selectedDate);
    _checkForDuplicate();
  }

  @override
  void dispose() {
    _menuNameController.dispose();
    super.dispose();
  }

  DateTime _computeDefaultDeadline(DateTime mealDate) {
    // Previous day at 8:00 PM (20:00) Asia/Kolkata -> 14:30 UTC
    final prevDay = mealDate.subtract(const Duration(days: 1));
    return DateTime.utc(prevDay.year, prevDay.month, prevDay.day, 14, 30);
  }

  String _formatDateString(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
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

  void _updateSuggestedMenuName() {
    if (!_isAutoMenuName) return;
    if (_selectedFoods.isEmpty) {
      _menuNameController.text = '';
    } else {
      _menuNameController.text =
          _selectedFoods.map((f) => f.foodName).join(' + ');
    }
  }

  Future<void> _checkForDuplicate() async {
    setState(() {
      _duplicateWarning = null;
    });

    try {
      final menuService = ref.read(menuServiceProvider);
      final exists = await menuService.checkDuplicateMeal(
        _formatDateString(_selectedDate),
        _selectedMealType,
      );

      if (mounted) {
        setState(() {
          if (exists) {
            _duplicateWarning =
                'A ${_selectedMealType.toUpperCase()} meal already exists for ${_formatDateString(_selectedDate)}.';
          }
        });
      }
    } catch (_) {
      // Ignore network errors during debounce check
    }
  }

  Future<void> _pickDate() async {
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final today = DateTime.utc(
        nowKolkata.year, nowKolkata.month, nowKolkata.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime.utc(picked.year, picked.month, picked.day);
        _responseDeadline = _computeDefaultDeadline(_selectedDate);
      });
      _checkForDuplicate();
    }
  }

  Future<void> _pickDeadline() async {
    final kolkataCurrent =
        _responseDeadline.toUtc().add(const Duration(hours: 5, minutes: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: kolkataCurrent,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: _selectedDate,
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

    // Convert picked local Kolkata time to UTC
    final localKolkataDt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // Subtract 5:30 to obtain UTC DateTime
    final utcDt = localKolkataDt.subtract(const Duration(hours: 5, minutes: 30));

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

  bool _isDeadlineValid() {
    // Deadline must be earlier than the meal date service time
    final mealDateStr = _formatDateString(_selectedDate);
    final parts = mealDateStr.split('-').map(int.parse).toList();
    // Interpreted as meal date 23:59:59 Kolkata time -> 18:29:59 UTC
    final endOfMealDayUtc =
        DateTime.utc(parts[0], parts[1], parts[2], 18, 30);

    return _responseDeadline.isBefore(endOfMealDayUtc);
  }

  Future<void> _handleCreateMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_duplicateWarning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_duplicateWarning!),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one food item to the meal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFoods.any((f) => f.portionGrams <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All food items must have a portion greater than 0g.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDeadlineValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response deadline must be before the meal date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(mealCreationNotifierProvider.notifier).createMeal(
            mealDate: _formatDateString(_selectedDate),
            mealType: _selectedMealType,
            menuName: _menuNameController.text.trim(),
            responseDeadline: _responseDeadline,
            items: _selectedFoods,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✓ Meal created successfully'),
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
    final createStatus = ref.watch(mealCreationNotifierProvider);
    final isSaving = createStatus.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning if duplicate
              if (_duplicateWarning != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _duplicateWarning!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Meal Date
              const Text(
                'Meal Date',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: Color(0xFF15803D)),
                      const SizedBox(width: 10),
                      Text(
                        _formatDisplayDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Meal Type
              const Text(
                'Meal Type',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedMealType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'breakfast',
                    child: Text('🍳 Breakfast'),
                  ),
                  DropdownMenuItem(
                    value: 'lunch',
                    child: Text('🍛 Lunch'),
                  ),
                  DropdownMenuItem(
                    value: 'dinner',
                    child: Text('🌙 Dinner'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMealType = val;
                    });
                    _checkForDuplicate();
                  }
                },
              ),
              const SizedBox(height: 16),

              // 3. Response Deadline
              const Text(
                'Response Deadline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Default recommended: Previous day at 8:00 PM (Asia/Kolkata)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          _formatDisplayDateTime(_responseDeadline),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF92400E)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Food Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Food Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final existingIds =
                          _selectedFoods.map((f) => f.foodItemId).toSet();
                      FoodItemSelectorSheet.show(
                        context,
                        existingFoodItemIds: existingIds,
                        onFoodSelected: (food) {
                          setState(() {
                            _selectedFoods.add(
                              MealItemEditData(
                                foodItemId: food.id,
                                foodName: food.name,
                                portionGrams: food.defaultPortionGrams > 0
                                    ? food.defaultPortionGrams
                                    : 100,
                              ),
                            );
                            _updateSuggestedMenuName();
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

              if (_selectedFoods.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No food items selected yet.\nTap "+ Add Food" to select items.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedFoods.length,
                  itemBuilder: (context, index) {
                    final item = _selectedFoods[index];
                    return MealEditorFoodRow(
                      item: item,
                      onPortionChanged: (portion) {
                        setState(() {
                          _selectedFoods[index] =
                              item.copyWith(portionGrams: portion);
                        });
                      },
                      onRemove: () {
                        setState(() {
                          _selectedFoods.removeAt(index);
                          _updateSuggestedMenuName();
                        });
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              // 5. Menu Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu Display Name',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAutoMenuName,
                        onChanged: (val) {
                          setState(() {
                            _isAutoMenuName = val ?? true;
                            if (_isAutoMenuName) {
                              _updateSuggestedMenuName();
                            }
                          });
                        },
                      ),
                      const Text('Auto-generate',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _menuNameController,
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
                onChanged: (val) {
                  if (_isAutoMenuName) {
                    setState(() {
                      _isAutoMenuName = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // 6. Meal Preview Card
              if (_selectedFoods.isNotEmpty) ...[
                const Text(
                  'Meal Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedMealType.toUpperCase()} • ${_formatDisplayDate(_selectedDate)}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _menuNameController.text.isNotEmpty
                            ? _menuNameController.text
                            : 'Menu Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._selectedFoods.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Text('• ',
                                    style: TextStyle(color: Colors.white70)),
                                Text(
                                  '${f.foodName} (${f.portionGrams}g)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(color: Colors.white24, height: 18),
                      Text(
                        'Response deadline: ${_formatDisplayDateTime(_responseDeadline)}',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleCreateMeal,
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Meal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
