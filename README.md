<div align="center">

<img src="assets/images/logo2.png" alt="Costly" width="120"/>

# Costly

**Smart expense tracking — know where your money goes.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*Cross‑platform personal finance app built with **Flutter** and **Firebase** — dashboard, history, analytics, and secure sign‑in in one polished UI.*

</div>

---

## App preview

<p align="center">
  <img src="docs/readme_images/Loading%20Screen.jpg" alt="Splash & loading" width="24%" />
  &nbsp;
  <img src="docs/readme_images/Home%20page.jpg" alt="Home dashboard" width="24%" />
  &nbsp;
  <img src="docs/readme_images/History%20page.jpg" alt="Transaction history" width="24%" />
  &nbsp;
  <img src="docs/readme_images/Analytics%20page.jpg" alt="Analytics" width="24%" />
</p>

<p align="center">
  <sub><b>Splash</b> · <b>Home</b> · <b>History</b> · <b>Analytics</b></sub>
</p>

---

## Highlights

| | |
|:---|:---|
| **Dashboard** | Month‑aware balance, income vs expenses, quick add, category grid, recent activity |
| **History** | Search, filters, category drill‑down, edit transactions, month selector |
| **Analytics** | Spending overview, rolling trends, category breakdown (charts) |
| **Account** | Email & Google sign‑in, profile & currency, Cloudinary profile photos |
| **Experience** | Purple brand theme, floating glass nav, entrance animations, modern splash |

---

## Tech stack

| Area | Choice |
|------|--------|
| UI | Flutter (Material 3) |
| State | Provider |
| Auth & data | Firebase Auth, Cloud Firestore |
| Charts | fl_chart |
| Media | image_picker, Cloudinary (uploads) |
| Local prefs | shared_preferences |

---

## Project layout

```
lib/
├── main.dart                 # Routes & theme
├── screens/                  # Splash, auth, home, history, analytics, profile, add flows
├── providers/                # Auth, transactions, categories
├── services/                 # Auth, Cloudinary, etc.
├── widgets/                  # Floating nav, animations, etc.
└── utils/                    # Constants, toasts
assets/images/                # Brand artwork
docs/readme_images/           # README screenshots
```

---

## Getting started

**Requirements:** Flutter SDK 3.x, a Firebase project (Auth + Firestore).

```bash
git clone https://github.com/YOUR_USERNAME/Costly.git
cd Costly
flutter pub get
```

Configure Firebase (e.g. [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)) so `lib/firebase_options.dart` and `android/app/google-services.json` match your project. Enable **Email/Password** and **Google** sign-in.

```bash
flutter run -d chrome    # web
flutter run -d android     # device / emulator
```

**Release APK**

```bash
flutter build apk --release
```

> Android Google Sign-In needs your keystore **SHA‑1/256** registered in Firebase for release builds.

---

## Screens (overview)

| Area | What you get |
|------|----------------|
| Splash | Branded load & sync before auth or home |
| Login / Register | Email/password + Google |
| Home | Balance, month picker, categories, recent tx |
| History | Filters, search, grouped list |
| Analytics | Totals, charts, month context |
| Profile | Avatar, currency, edit profile, sign out |
| Add expense / income | Categories, amount, date, notes |

---

## Roadmap ideas

- Budget alerts per category  
- Export (CSV/PDF)  
- Dark mode  
- Richer notifications  

---

## Contributing

1. Fork the repo  
2. Branch: `feature/your-idea`  
3. Commit with clear messages  
4. Open a Pull Request  

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

**Built with Flutter**

If this repo helps you, consider starring it on GitHub.

</div>
