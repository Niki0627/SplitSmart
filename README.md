# SplitSmart

SplitSmart is a Flutter application designed to help you easily split bills and settle expenses with friends. Say goodbye to awkward money conversations and keep track of who owes what seamlessly.

## Features

- **Authentication**: Secure login using Google Sign-In and email via Firebase Authentication.
- **Group Expense Management**: Create groups, add expenses, and automatically calculate who owes whom.
- **Contacts Integration**: Easily add friends to groups directly from your device's contact list.
- **Smart Settlements**: Settle up quickly with integrated Google Pay (UPI) deep linking for seamless payments.
- **User Profiles**: Customizable user profiles with avatars and personal settings.
- **Analytics & Insights**: Visual breakdowns of your spending using interactive charts (powered by `fl_chart`).

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend & Database**: Firebase (Authentication, Cloud Firestore)
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing**: `go_router`
- **UI Components**: `google_fonts`, `fl_chart`, `cached_network_image`, `shimmer`
- **Utilities**: `flutter_contacts`, `url_launcher` (GPay deep linking), `permission_handler`

## Project Structure

The project follows a feature-centric architecture:

- `lib/core/`: Application-wide utilities, theme definitions, routing configuration, etc.
- `lib/features/`: Contains all the domain-specific features of the app (e.g., Auth, Groups, Expenses, Profile, Contacts).
- `lib/shared/`: Shared components, widgets, and services reused across different features.

## Getting Started

### Prerequisites

- Flutter SDK (>=3.4.0 <4.0.0)
- A Firebase project configured for Flutter (ensure `firebase_options.dart` and `google-services.json`/`GoogleService-Info.plist` are correctly set up).

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```bash
   cd splitsmart
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the code generation for Riverpod (if necessary):
   ```bash
   dart run build_runner build -d
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
