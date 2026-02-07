# legalai_frontend

A new Flutter project.

## Firebase setup

- **Client config (used by the app):**  
  The app uses `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` for Firebase.  
  `lib/firebase_options.dart` is generated from those files so `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` works.  
  To regenerate it, run: `dart run flutterfire configure` (requires [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)).

- **Admin SDK JSON (backend only):**  
  Files like `legalai-b363d-firebase-adminsdk-*.json` are for **server-side only** (e.g. Cloud Functions, backend).  
  Do **not** use them in this Flutter app; they are not for “Firebase login and configure” in the frontend.

- **Google Sign-In:**  
  For “Sign in with Google” on Android/iOS, set `GOOGLE_SERVER_CLIENT_ID` (e.g. your Firebase Web client ID from Project settings → Your apps).  
  Optional: set `GOOGLE_WEB_CLIENT_ID` for web. See `env.example.json` and `AppConstants` in the codebase.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
