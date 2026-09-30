import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_response.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final userMealResponsesProvider =
    FutureProvider.family<List<FoodResponse>, int>((ref, mealId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final responseService = ref.watch(responseServiceProvider);
  return responseService.getCurrentUserResponses(
    mealId: mealId,
    userId: user.id,
  );
});

class SaveResponsesNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> saveResponses({
    required int mealId,
    required Map<int, bool> mealItemResponses,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('User is not authenticated');

    state = const AsyncValue.loading();
    try {
      final responseService = ref.read(responseServiceProvider);
      await responseService.saveResponses(
        userId: user.id,
        mealItemResponses: mealItemResponses,
      );
      // Invalidate the cache to reload fresh responses from Supabase
      ref.invalidate(userMealResponsesProvider(mealId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final saveResponsesNotifierProvider =
    NotifierProvider<SaveResponsesNotifier, AsyncValue<void>>(
        SaveResponsesNotifier.new);
