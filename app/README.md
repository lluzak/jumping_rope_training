# Skakanka HIIT – aplikacja iOS

Natywna wersja minutnika do treningu HIIT na skakance (Flutter, tylko iOS).

Względem wersji webowej:

- **Muzyka gra dalej.** Sygnały miksują się z muzyką z innych aplikacji, a na czas komunikatu głosowego muzyka jest tylko ściszana, nie zatrzymywana (`ios/Runner/AudioCoach.swift`, sesja audio `.playback` + `.duckOthers`).
- **Apple Zdrowie.** Ukończony trening zapisuje się jako „Skakanka” (`HKWorkoutActivityType.jumpRope`) z szacowanymi kaloriami. Aplikacja odczytuje wagę (do szacowania kalorii) i średnie tętno z czasu treningu, np. z Apple Watch.
- Ekran nie gaśnie w trakcie treningu, a po powrocie z tła zegar nadrabia czas.

## Instalacja na iPhonie

Potrzebny jest Mac z Xcode i [Flutterem](https://docs.flutter.dev/get-started/install/macos/mobile-ios).

```sh
cd app
flutter pub get
open ios/Runner.xcworkspace
```

W Xcode: target **Runner** → **Signing & Capabilities** → **Team**: wybierz swoje Apple ID (Add Account…, jeśli go nie ma). Jeśli identyfikator `com.lluzak.skakanka` jest zajęty, zmień **Bundle Identifier** na własny. HealthKit jest już włączony w `Runner.entitlements`.

Podłącz iPhone'a kablem, włącz na nim **Ustawienia → Prywatność i ochrona → Tryb dewelopera**, potem:

```sh
flutter run --release
```

Za pierwszym razem zaufaj certyfikatowi na iPhonie: **Ustawienia → Ogólne → VPN i urządzenia zarządzane**.

Z darmowym Apple ID aplikacja działa 7 dni, potem trzeba ją zainstalować ponownie tą samą komendą. Płatne konto Apple Developer (99 USD/rok) daje roczne certyfikaty i TestFlight.

## Rozwój

```sh
flutter analyze
flutter test
```

CI (`.github/workflows/app.yml`) uruchamia analizę i testy na Linuksie oraz buduje aplikację iOS bez podpisu na macOS.
