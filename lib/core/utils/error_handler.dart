import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials')) {
        return 'Incorrect email or password. Please try again.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Please confirm your email address before logging in.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('user already exists')) {
        return 'An account with this email already exists.';
      }
      if (msg.contains('database error saving new user')) {
        return 'Registration failed: This roll number or email is already registered, or required fields are missing.';
      }
      return error.message;
    }

    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (error.code == '23505') {
        if (msg.contains('roll_number')) {
          return 'A profile with this roll number already exists.';
        }
        if (msg.contains('meals_meal_date_meal_type_key')) {
          return 'A meal of this type already exists on this date.';
        }
        if (msg.contains('food_responses_meal_item_id_user_id_key')) {
          return 'You have already submitted a response for this food item.';
        }
        if (msg.contains('waste_logs_meal_id_key')) {
          return 'A waste log has already been recorded for this meal.';
        }
        return 'A record with this information already exists.';
      }

      if (error.code == '42501' ||
          msg.contains('permission denied') ||
          msg.contains('row-level security')) {
        if (msg.contains('response_deadline') || msg.contains('deadline')) {
          return 'Responses are closed for this meal as the response deadline has passed.';
        }
        return 'You do not have permission to perform this action.';
      }

      if (msg.contains('response_deadline') || msg.contains('deadline')) {
        return 'Response deadline has passed. Submissions are now closed.';
      }

      return 'Database operation failed: ${error.message}';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('connection refused') ||
        message.contains('clientexception')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (error is Exception) {
      final str = error.toString();
      if (str.startsWith('Exception: ')) {
        return str.substring('Exception: '.length);
      }
    }

    return 'An unexpected error occurred: ${error.toString()}';
  }
}
