import 'meal.dart';

class ActionableMealGroup {
  final String mealDate; // 'YYYY-MM-DD'
  final DateTime date;
  final List<Meal> meals;
  final bool isActionable; // true if at least one meal has an open response deadline
  final DateTime? earliestDeadline;
  final bool isNextActionable; // true if this is the active target meal day

  const ActionableMealGroup({
    required this.mealDate,
    required this.date,
    required this.meals,
    required this.isActionable,
    this.earliestDeadline,
    this.isNextActionable = false,
  });

  String formatDisplayDate() {
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayKolkata =
        DateTime.utc(nowKolkata.year, nowKolkata.month, nowKolkata.day);

    final parts = mealDate.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) {
      return mealDate;
    }

    final groupDate = DateTime.utc(parts[0]!, parts[1]!, parts[2]!);
    final diffDays = groupDate.difference(todayKolkata).inDays;

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final dateStr = '${months[parts[1]! - 1]} ${parts[2]!}';

    if (diffDays == 1) {
      return "Tomorrow's Meals • $dateStr";
    } else if (diffDays == 0) {
      return "Today's Meals • $dateStr";
    } else {
      return "Upcoming Meals • $dateStr";
    }
  }

  String? formatEarliestDeadline() {
    if (earliestDeadline == null) return null;
    final kolkataTime =
        earliestDeadline!.toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayKolkata =
        DateTime.utc(nowKolkata.year, nowKolkata.month, nowKolkata.day);
    final deadlineDay = DateTime.utc(
        kolkataTime.year, kolkataTime.month, kolkataTime.day);
    final diffDays = deadlineDay.difference(todayKolkata).inDays;

    final hour = kolkataTime.hour;
    final minute = kolkataTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final timeStr = '$formattedHour:$minute $period';

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

    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Tomorrow, $timeStr';
    } else {
      return '${months[kolkataTime.month - 1]} ${kolkataTime.day}, $timeStr';
    }
  }
}
