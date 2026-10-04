# Food Waste Reduction App

A Flutter mobile application designed to reduce food waste in a hostel or campus dining environment by aligning meal preparation with real student demand. The app supports two primary user roles:

- Students can review upcoming meals, respond with their preferences, and indicate which items they want to consume.
- Staff/admin users can plan menus, track food demand, record waste, and monitor trends over time.

The application uses Flutter for the frontend and Supabase as the backend/Auth/data layer, with Riverpod for state management and GoRouter for navigation.

## Overview

This project focuses on reducing unnecessary food waste by giving administrators better visibility into meal demand and by encouraging students to respond to meal availability before food is prepared. Instead of preparing meals based on estimates alone, the system lets canteen staff plan around actual food preferences, course/year demand, and historical waste patterns.

The app is structured around a role-based flow:

- Student dashboard: shows upcoming and actionable meals, profile info, and response cards.
- Admin dashboard: shows canteen metrics, meal planning tools, waste logging screens, and statistics.
- Supabase backend: stores user accounts, profiles, courses, meal data, food responses, and waste records.

## Key Features

### Student features

- Authentication with email/password via Supabase Auth
- Student profile creation and role-based access
- View upcoming meal plans and active response windows
- Submit meal preference responses per food item
- Review current or historical responses for a specific meal
- Access role-specific routing and redirects after login

### Admin features

- Staff/admin login and protected admin dashboard
- Create, edit, and manage meal menus
- Schedule meals by date and meal type
- Configure food portions and menu items
- View meal detail pages with response summaries
- Record meal waste with prepared, served, and wasted portions
- View aggregated food waste statistics using charts
- Analyze food demand by course and study year
- Use prediction-based recommendations for preparation planning

### Data and analytics

- Meal demand aggregation through Supabase RPC functions
- Course/year-based demand analysis
- Waste trend reports over the last 7 days
- Explainable food quantity prediction logic from backend computed data

## Tech Stack

- Flutter / Dart
- Riverpod for state management
- GoRouter for route management
- Supabase Flutter for authentication and database access
- Material 3 design system
- fl_chart for analytics visualization

## Project Structure

```text
foodwaste_reduction/
├── android/                  # Android project files
├── ios/                     # iOS project files
├── linux/                  # Linux desktop project files
├── macos/                  # macOS project files
├── windows/                # Windows desktop project files
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── supabase_config.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       ├── error_handler.dart
│   │       └── validators.dart
│   ├── models/              # Data models for profiles, meals, waste, etc.
│   ├── providers/           # Riverpod providers and controllers
│   ├── routing/
│   │   └── app_router.dart
│   ├── screens/
│   │   ├── admin/           # Admin dashboard and menu management UI
│   │   ├── auth/            # Login and registration screens
│   │   └── student/         # Student home and meal response UI
│   ├── services/            # Supabase service layer
│   ├── widgets/             # Reusable widgets and cards
│   ├── app.dart             # Root app configuration
│   ├── main.dart            # App bootstrap
│   └── ...
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
├── .gitignore
├── README.md
└── ...
```

## Application Flow

### Authentication and routing

The app bootstraps in `main.dart`, initializes Supabase, and wraps the app in `ProviderScope`.

The router in `lib/routing/app_router.dart` performs role-aware redirects:

- unauthenticated users are redirected to `/login`
- authenticated student users are sent to `/student`
- authenticated admin users are sent to `/admin`
- role mismatches trigger automatic redirection

This ensures students cannot access admin-only screens and vice versa.

### Student interaction flow

1. Student logs in or registers an account.
2. A profile is loaded and linked to the authenticated user.
3. The student lands on the student dashboard.
4. Upcoming actionable meal groups are displayed.
5. The student chooses their preferred food items for the relevant meal.
6. Responses are saved to Supabase and linked to the student profile.

### Admin interaction flow

1. Admin logs in.
2. The admin dashboard loads meal summaries and profile details.
3. Admin can create or manage menu items for upcoming meals.
4. Meal details can be opened for demand insights and planning decisions.
5. Waste logs can be added after a meal is served.
6. Statistics screen shows trends and preparation recommendations.

## Core Modules

### `lib/models`

Contains the domain models used throughout the app, including:

- `Profile`
- `Meal`
- `FoodItem`
- `FoodResponse`
- `WasteLog`
- `WasteStatistic`
- `Course`, `StudyYear`, and demand objects used in reporting

### `lib/services`

The service layer encapsulates Supabase operations per domain:

- `auth_service.dart`: account sign-in/sign-up/logout
- `profile_service.dart`: fetch and update student/admin profile data
- `menu_service.dart`: create, update, and fetch meals and meal items
- `response_service.dart`: save student meal responses and demand queries
- `waste_service.dart`: record waste logs and calculate waste data
- `dashboard_service.dart`: fetch meal demand and prediction results via RPC

### `lib/providers`

Providers are built with Riverpod and expose app state in a centralized way:

- `auth_provider.dart`
- `profile_provider.dart`
- `meal_provider.dart`
- `menu_provider.dart`
- `response_provider.dart`
- `dashboard_provider.dart`
- `supabase_provider.dart`

### `lib/screens`

The application UI is organized into separate screens for each role and domain:

- `auth/login_screen.dart`
- `auth/register_screen.dart`
- `student/student_home_screen.dart`
- `student/meal_response_screen.dart`
- `admin/admin_dashboard_screen.dart`
- `admin/menu_management_screen.dart`
- `admin/create_meal_screen.dart`
- `admin/edit_meal_screen.dart`
- `admin/meal_detail_screen.dart`
- `admin/waste_entry_screen.dart`
- `admin/waste_stats_screen.dart`

## Supabase Integration

This app expects a Supabase project with the following responsibilities:

- Authentication using email/password accounts
- PostgreSQL tables for profiles, meals, food items, responses, and waste logs
- Row-level security (RLS) policies for student/admin access
- Database functions or RPCs for analytics

The app reads project configuration from:

- `lib/core/constants/supabase_config.dart`

The default values are already populated for development convenience, but production setups should replace them with your own secure project credentials:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);
```

You can also pass environment variables during a build or run session:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Database and Analytics Expectations

The dashboard and analytics screens depend on backend queries and stored procedures such as:

- `get_meal_food_demand`
- `get_meal_demand_by_course_year`
- `predict_meal_food_quantity`
- `get_waste_statistics`

This means the Supabase database must expose the corresponding SQL functions or equivalent result sets for demand and waste reporting.

## Getting Started

### Prerequisites

- Flutter SDK (version compatible with the project as declared in `pubspec.yaml`)
- Android Studio / Xcode / VS Code with Flutter support
- A Supabase project with authentication and database enabled

### Installation

1. Clone the repository.
2. Open the project in VS Code or Android Studio.
3. Install dependencies:

```bash
flutter pub get
```

4. Ensure your Supabase credentials are configured.
5. Run the app:

```bash
flutter run
```

Optional platform-specific runs:

```bash
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

### Useful development commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

## Common Use Cases

- A student logs in and responds to the next meal before the response deadline.
- An admin creates a breakfast or dinner menu several days ahead.
- The staff checks demand distribution by course/year and prepares the right portions.
- After meal service, the admin logs actual prepared and wasted quantities.
- The analytics screen highlights the waste rate and highlights operational improvement opportunities.

## Notes

This project is designed as a practical campus/hostel food management app and is especially useful in institutions where meal preparation is repeated daily and waste reduction is a priority. The architecture is modular and extensible, making it straightforward to add:

- push notifications for meal deadlines
- exportable reports as CSV or PDF
- multi-campus support
- admin role permissions and audit logs
- more advanced AI-based food forecasting

## License

This project currently does not declare a custom license in the repository metadata. Please confirm with the repository owner before publishing, redistributing, or commercializing the application.

## Summary

Food Waste Reduction is a complete full-stack Flutter application for smarter hostel/canteen meal planning. It combines student participation, admin oversight, and data-driven analytics to reduce excessive food preparation and encourage more sustainable consumption patterns.
