# Quizistan Academy — App Architecture

**"Board ki Tayyari"** — Punjab board exam-prep app (9 BISE boards, classes 9–12, all subjects).

## Tech stack
- **Flutter** (Material 3) — single codebase for Android
- **Firebase**: Auth (anonymous + phone), Cloud Firestore (question bank, test rooms, results)
- **State**: `provider` + `ChangeNotifier` (simple, student-maintainable)
- **Ads**: `google_mobile_ads` (AdMob, free plan)
- **Premium**: `in_app_purchase` (remove ads + premium features)
- **Local cache**: `shared_preferences`

## Brand
- Colors: deep blue `#1B3FAB` → purple `#7B2FF7` → orange `#FF7A1A` (from logo gradient)
- Logo: `assets/quizistan-logo.webp` (3D Q + graduation cap + book + tick)

## Folder layout (lib/)
```
lib/
  main.dart
  core/
    theme/app_theme.dart
    constants/app_constants.dart
    utils/validators.dart
  models/
    question.dart
    quiz_session.dart
    quiz_result.dart
    test_room.dart
    app_user.dart
  services/
    auth_service.dart
    firestore_service.dart
    quiz_engine.dart        (ChangeNotifier)
    ad_service.dart
    purchase_service.dart
  screens/
    splash/splash_screen.dart
    home/home_screen.dart
    quiz/setup_quiz_screen.dart      (board/class/subject/chapter picker)
    quiz/quiz_screen.dart            (timer, instant feedback)
    quiz/result_screen.dart          (score + mistake review)
    bank/question_bank_screen.dart   (search / add / edit / delete)
    maker/test_maker_screen.dart     (teacher: build test from filters)
    live/live_room_host_screen.dart  (teacher: create room, monitor)
    live/live_room_join_screen.dart  (student: join by code)
    plans/plans_screen.dart          (free vs premium)
    profile/profile_screen.dart
  widgets/
    app_logo.dart
    question_card.dart
    timer_ring.dart
    option_button.dart
```

## Data models (Firestore)
- `questions/{id}`: board, classLevel, subject, chapter, text, options[4], correctIndex, explanation, createdBy, createdAt
- `users/{uid}`: name, role (student/teacher), board, classLevel, isPremium, createdAt
- `rooms/{code}`: hostUid, testId, status (waiting/live/ended), createdAt
- `rooms/{code}/participants/{uid}`: name, score, answers{}, joinedAt
- `results/{id}`: uid, filters, totalQuestions, correct, wrong, skipped, durationSecs, createdAt

## Key flows
1. **Student quiz**: Home → Setup (board/class/subject/chapter, count) → Quiz (per-question timer, instant feedback) → Result (score, mistake review, retry wrong)
2. **Question bank**: searchable list; teachers can add/edit/delete
3. **Test Maker**: teacher picks filters + count → generates printable/shareable test
4. **Live Room**: teacher creates room → 6-char code → students join → teacher starts → live leaderboard → ends → results saved
5. **Monetization**: free = banner ads + daily quiz limit; premium = no ads + unlimited + test maker

## Conventions
- All user-facing text in **Roman Urdu + simple English** mix (user's audience), never Urdu script
- Null safety, `const` where possible, no `print` in production code (use `debugPrint`)
- Every screen handles loading / empty / error states
