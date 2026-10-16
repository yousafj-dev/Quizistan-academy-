Quizistan Academy — Android launcher icon files
================================================

Files:
- ic_launcher.xml          -> android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
- ic_launcher_round.xml    -> android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml
- ic_launcher_foreground.webp -> android/app/src/main/res/drawable/ic_launcher_foreground.webp
- colors.xml               -> android/app/src/main/res/values/colors.xml
  (agar colors.xml pehle se ho to sirf ic_launcher_background wali line us me add kar do)

Steps (PC par, Flutter installed hone ke baad):
1. quizistan-app folder me:  flutter create --org com.quizistan .
2. Upar di hui files ko unki jagah copy karo.
3. android/app/src/main/AndroidManifest.xml me check karo:
      android:icon="@mipmap/ic_launcher"
4. flutter build appbundle --release

Note: foreground logo ke ird-gird khaali jagah (padding) hai taake
gol/murabba icon shapes me Q kat na jaye.
