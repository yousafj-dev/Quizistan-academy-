# Firebase Setup Guide — Quizistan Academy

Ye guide tumhe (ya mamu ke) Google account par Firebase project banane me madad karegi.
Waqt: lagbhag 20–30 minute.

## Step 1 — Firebase project banao
1. https://console.firebase.google.com kholo aur Google account se login karo.
2. **Add project** → naam rakho: `Quizistan Academy` → Continue.
3. Google Analytics: **Enable** kar do (free hai) → Create project.

## Step 2 — Android app add karo
1. Project ke dashboard par **Android icon** (Add an app) par click karo.
2. **Android package name**: `com.quizistan.academy`
   (ye naam poori zindagi app ka rahega — change nahi hota, dhyan se likho)
3. App nickname: `Quizistan Academy` → Register app.
4. **google-services.json** download karo.
5. Is file ko Flutter project me yahan rakho:
   ```
   quizistan-app/android/app/google-services.json
   ```

## Step 3 — Authentication on karo
1. Firebase console → **Build → Authentication** → Get started.
2. **Sign-in method** tab → **Anonymous** → Enable → Save.
   (App me abhi anonymous login hai — baad me Phone login add kar sakte ho.)

## Step 4 — Firestore Database banao
1. **Build → Firestore Database** → Create database.
2. Location: `asia-south1` (Mumbai — Pakistan ke sab se qareeb) → Enable.
3. Start in **production mode** → neeche diye gaye Rules lagao.

## Step 5 — Security Rules
**Rules** tab me ye paste karo aur Publish dabao:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Question bank: sab parh sakte hain, sirf login user likh sakta hai
    match /questions/{id} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    // User profiles: apni profile khud
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    // Test rooms: login users
    match /rooms/{code} {
      allow read, write: if request.auth != null;
      match /participants/{pid} {
        allow read, write: if request.auth != null;
      }
    }
    // Results: apne results khud
    match /results/{id} {
      allow read, write: if request.auth != null;
    }
    // Tests (Test Maker): login users
    match /tests/{id} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 6 — Flutter project me Firebase lagao (PC par)
Jab tumhare PC par Flutter installed ho, project folder me ye commands chalao:

```bash
flutter pub add firebase_core firebase_auth cloud_firestore
dart pub global activate flutterfire_cli
flutterfire configure --project=quizistan-academy
```

Ye `lib/firebase_options.dart` bana dega. Phir `lib/main.dart` me:

```dart
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuizistanApp());
}
```

(Note: coordinator ne main.dart me pehle se guarded Firebase init dala hua hai —
`firebase_options.dart` banne ke baad usay is proper init se replace kar dena.)

## Done!
Firebase ready. Ab app me login, question bank aur live room asal data par chalenge.
