import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/meal_edit_data.dart';

class MenuService {
  final SupabaseClient _supabase;

  MenuService(this._supabase);

  String _getTodayKolkataString() {
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return "${nowKolkata.year.toString().padLeft(4, '0')}-${nowKolkata.month.toString().padLeft(2, '0')}-${nowKolkata.day.toString().padLeft(2, '0')}";
  }

  Future<List<Meal>> getUpcomingMealsForAdmin({int days = 14}) async {
    final todayStr = _getTodayKolkataString();
    debugPrint('MENU_SERVICE: Fetching admin upcoming meals from date=$todayStr');

    final response = await _supabase
        .from('meals')
        .select('*, meal_items(*, food_items(*))')
        .gte('meal_date', todayStr)
        .order('meal_date', ascending: true)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => Meal.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<FoodItem>> getActiveFoodItems() async {
    debugPrint('MENU_SERVICE: Fetching active food items catalogue');
    final response = await _supabase
        .from('food_items')
        .select('*')
        .eq('active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => FoodItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<bool> checkDuplicateMeal(
    String mealDate,
    String mealType, {
    int? excludeMealId,
  }) async {
    var query = _supabase
        .from('meals')
        .select('id')
        .eq('meal_date', mealDate)
        .eq('meal_type', mealType.toLowerCase());

    if (excludeMealId != null) {
      query = query.neq('id', excludeMealId);
    }

    final response = await query.maybeSingle();
    return response != null;
  }

  Future<MealEditData?> getMealForEditing(int mealId) async {
    debugPrint('MENU_SERVICE: Fetching meal details for editing, mealId=$mealId');

    // 1. Fetch meal with items and food catalog
    final mealRes = await _supabase
        .from('meals')
        .select('*, meal_items(*, food_items(*))')
        .eq('id', mealId)
        .maybeSingle();

    if (mealRes == null) return null;
    final meal = Meal.fromJson(mealRes);

    // 2. Check if waste log exists
    final wasteRes = await _supabase
        .from('waste_logs')
        .select('id')
        .eq('meal_id', mealId)
        .maybeSingle();
    final hasWasteLog = wasteRes != null;

    // 3. Determine if past meal based on Asia/Kolkata
    final todayStr = _getTodayKolkataString();
    final isPastMeal = meal.mealDate.compareTo(todayStr) < 0;

    // 4. Fetch response counts for all meal items
    final itemIds = meal.mealItems.map((i) => i.id).toList();
    final Set<int> itemsWithResponses = {};
    final Map<int, int> responseCounts = {};

    if (itemIds.isNotEmpty) {
      final responsesRes = await _supabase
          .from('food_responses')
          .select('meal_item_id')
          .inFilter('meal_item_id', itemIds);

      for (var row in responsesRes as List) {
        final itemId = (row['meal_item_id'] as num).toInt();
        itemsWithResponses.add(itemId);
        responseCounts[itemId] = (responseCounts[itemId] ?? 0) + 1;
      }
    }

    final List<MealItemEditData> editItems = meal.mealItems.map((item) {
      final hasResp = itemsWithResponses.contains(item.id);
      final count = responseCounts[item.id] ?? 0;
      return MealItemEditData(
        id: item.id,
        foodItemId: item.foodItemId,
        foodName: item.foodItem?.name ?? 'Food Item',
        portionGrams: item.portionGrams,
        hasResponses: hasResp,
        responseCount: count,
      );
    }).toList();

    return MealEditData(
      meal: meal,
      items: editItems,
      hasWasteLog: hasWasteLog,
      isPastMeal: isPastMeal,
    );
  }

  Future<Meal> createMealWithItems({
    required String mealDate,
    required String mealType,
    required String menuName,
    required DateTime responseDeadline,
    required List<MealItemEditData> items,
  }) async {
    // 1. Validation check for duplicate
    final isDuplicate = await checkDuplicateMeal(mealDate, mealType);
    if (isDuplicate) {
      throw Exception(
          'A ${mealType.toLowerCase()} meal already exists for $mealDate. Please edit the existing meal instead.');
    }

    if (items.isEmpty) {
      throw Exception('At least one food item must be added to the meal.');
    }

    // Calculate average portion grams
    final totalGrams =
        items.fold<int>(0, (sum, item) => sum + item.portionGrams);
    final avgPortionGrams = (totalGrams / items.length).round();

    // 2. Insert into meals
    final mealInsertRes = await _supabase
        .from('meals')
        .insert({
          'meal_date': mealDate,
          'meal_type': mealType.toLowerCase(),
          'menu_name': menuName.trim(),
          'average_portion_grams': avgPortionGrams,
          'response_deadline': responseDeadline.toUtc().toIso8601String(),
        })
        .select()
        .single();

    final newMealId = (mealInsertRes['id'] as num).toInt();

    // 3. Insert meal_items
    try {
      final itemsPayload = items.map((item) {
        return {
          'meal_id': newMealId,
          'food_item_id': item.foodItemId,
          'portion_grams': item.portionGrams,
        };
      }).toList();

      await _supabase.from('meal_items').insert(itemsPayload);
    } catch (e) {
      debugPrint('MENU_SERVICE: Error inserting meal items: $e');
      throw Exception(
          'Meal record created, but failed to save food items: $e');
    }

    // 4. Return full created meal
    final createdMealRes = await _supabase
        .from('meals')
        .select('*, meal_items(*, food_items(*))')
        .eq('id', newMealId)
        .single();

    return Meal.fromJson(createdMealRes);
  }

  Future<void> updateMealWithItems({
    required int mealId,
    required String menuName,
    required DateTime responseDeadline,
    required List<MealItemEditData> currentItems,
    required List<int> itemIdsToDelete,
  }) async {
    // 1. Safety check on response-integrity: verify none of the deleted items have responses
    if (itemIdsToDelete.isNotEmpty) {
      final existingResponses = await _supabase
          .from('food_responses')
          .select('meal_item_id')
          .inFilter('meal_item_id', itemIdsToDelete);

      if ((existingResponses as List).isNotEmpty) {
        throw Exception(
            'Cannot remove food items that already have student responses.');
      }

      // Safe to delete
      await _supabase
          .from('meal_items')
          .delete()
          .inFilter('id', itemIdsToDelete);
    }

    // 2. Calculate average portion grams
    final totalGrams =
        currentItems.fold<int>(0, (sum, item) => sum + item.portionGrams);
    final avgPortionGrams = currentItems.isNotEmpty
        ? (totalGrams / currentItems.length).round()
        : 0;

    // 3. Update meals table
    await _supabase.from('meals').update({
      'menu_name': menuName.trim(),
      'average_portion_grams': avgPortionGrams,
      'response_deadline': responseDeadline.toUtc().toIso8601String(),
    }).eq('id', mealId);

    // 4. Update existing items and insert new items
    for (var item in currentItems) {
      if (item.id != null) {
        // Update existing meal_item portion
        await _supabase.from('meal_items').update({
          'portion_grams': item.portionGrams,
        }).eq('id', item.id!);
      } else {
        // Insert new meal_item
        await _supabase.from('meal_items').insert({
          'meal_id': mealId,
          'food_item_id': item.foodItemId,
          'portion_grams': item.portionGrams,
        });
      }
    }
  }
}
