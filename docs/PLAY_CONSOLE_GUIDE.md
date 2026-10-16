# Play Console Upload Guide — Quizistan Academy

## Part A — Play Console account (mamu ke naam par)

**Chahiye hoga:**
- Mamu ke naam par fresh **Gmail**
- Mamu ka **bank card** (Visa/Mastercard, international payments on)
- Mamu ka **phone number**
- Mamu ka **CNIC**
- **$25** (lagbhag Rs 7,000–7,500)

**Steps:**
1. https://play.google.com/console par nayi Gmail se jao → **Sign up**.
2. Account type: **Personal** chuno.
3. $25 fee card se pay karo.
4. Identity verification: CNIC ki photo + kabhi kabhi selfie/video mangte hain — mamu khud karein.
5. **2–3 din** me verification complete hoti hai.

> Yaad rakho: account hamesha mamu ke naam rahega — yehi legal owner hoga.

## Part B — App ko release ke liye tayyar karo (PC par)

```bash
cd quizistan-app

# 1. Icon lagao (neeche Part D dekho), phir:
flutter pub get

# 2. Release AAB banao:
flutter build appbundle --release
```

AAB milegi: `build/app/outputs/bundle/release/app-release.aab`

**Version:** `pubspec.yaml` me `version: 1.0.0+1` hai. Har nayi release par `+1` ka number barhao (1.0.0+2, ...).

## Part C — Play Console me app banao

1. Play Console → **Create app** → naam: `Quizistan Academy`
2. Default language: **English (US)** → App or game: **App** → Free or paid: **Free** (premium baad me in-app purchase se).
3. **Declarations** poori karo (privacy policy link chahiye — neeche dekho).
4. **App signing**: Google Play App Signing **on** rakho (recommended).
5. **Content rating** questionnaire bharo (Educational app → Everyone).
6. **Data safety** form: batayo ke Firebase Auth + Firestore data collect hota hai.
7. **Privacy policy**: ek simple page chahiye. Free generator use kar sakte ho, ya mujh se banwa lo.

## Part D — App icon lagana

1. Project me ye command chalao (platform folders banane ke liye):
   ```bash
   flutter create --org com.quizistan .
   ```
2. `docs/android-icon/` folder me di hui files ko yahan copy karo:
   - `ic_launcher.xml` → `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
   - `ic_launcher_round.xml` → `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
   - `ic_launcher_foreground.webp` → `android/app/src/main/res/drawable/ic_launcher_foreground.webp`
   - `colors.xml` → `android/app/src/main/res/values/colors.xml`
3. `android/app/src/main/AndroidManifest.xml` me ye line hai, confirm karo:
   ```xml
   android:icon="@mipmap/ic_launcher"
   ```

## Part E — Testing (lazmi!)

Naye personal accounts ke liye Google **lazmi** karta hai:
- Kam az kam **12 testers**
- **14 din** musalsal opted-in

**Steps:**
1. Play Console → **Testing → Closed testing** → nayi track banao.
2. AAB upload karo → tester emails add karo (12 doston/teachers ke Gmail).
3. Unhe link bhejo — wo opt-in karke app install karein.
4. 14 din baad **Production** release ka option khul jayega.

## Part F — Production release

1. **Production → Create new release** → AAB upload karo.
2. Release notes likho (Roman Urdu/English): "Pehli release — Board ki Tayyari!"
3. **Store listing**: app icon, feature graphic, 2–4 screenshots, short + full description.
4. Review ke liye bhejo — **3–7 din** me Google review karta hai.

## Checklist (aik nazar me)
- [ ] Play Console account + $25 + verification
- [ ] Firebase setup (FIREBASE_SETUP.md)
- [ ] Asli AdMob App ID + ad unit IDs (AdMob account banao)
- [ ] Asli in-app product `quizistan_premium` Play Console me banao
- [ ] Privacy policy page
- [ ] App icon + screenshots + feature graphic
- [ ] 12 testers × 14 din
- [ ] Production release 🚀
