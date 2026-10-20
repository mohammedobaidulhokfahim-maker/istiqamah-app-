# Istiqamah (LifeForge)

## Setup (once)
1. In a terminal: `flutter create --org com.example --project-name istiqamah .`
   (run inside an empty folder), then copy `lib/`, `pubspec.yaml` and
   `android/app/src/main/AndroidManifest.xml` from this project over the new ones.
2. Open `android/app/build.gradle(.kts)` and add:

   Groovy (`build.gradle`):
   ```
   android {
       compileSdk 35
       compileOptions {
           coreLibraryDesugaringEnabled true
           sourceCompatibility JavaVersion.VERSION_11
           targetCompatibility JavaVersion.VERSION_11
       }
   }
   dependencies {
       coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
   }
   ```
   Kotlin (`build.gradle.kts`):
   ```
   android {
       compileSdk = 35
       compileOptions {
           isCoreLibraryDesugaringEnabled = true
           sourceCompatibility = JavaVersion.VERSION_11
           targetCompatibility = JavaVersion.VERSION_11
       }
   }
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   }
   ```
3. `flutter pub get` then `flutter run` on a real Android phone.

## Notes
- Notifications for the next 3 days are scheduled each time the app opens;
  a 12-hour background alarm keeps them topped up.
- Persistent alarm = alarm-category notification with the insistent flag
  (sound repeats until you react).
- Nagging: first alert, then 3 more every 5 minutes. "Done" stops them;
  "Snooze 10m" restarts them after 10 minutes.
- The app cannot detect if you are lying down. The stand-up nudges are timed reminders.
- Counter click sound uses the system click sound (no audio file needed).
- Verify the dua texts with a trusted teacher.
