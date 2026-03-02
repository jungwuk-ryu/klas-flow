# Flutter Demo App

This folder is a runnable Flutter app that demonstrates:

- Login with student ID and password
- Session info rendering
- Context list rendering and context switching
- Task list rendering from `learning.taskStdList`

## Run

```bash
cd example
flutter pub get
flutter run
```

Windows desktop run:

```bash
flutter run -d windows
```

Prerequisite for Windows desktop:
- Install Visual Studio 2022 (or Build Tools) with `Desktop development with C++`.
- Verify with `flutter doctor -v` that Visual Studio shows no error.

If you run on Flutter Web (`localhost`) with the default base URL
(`https://klas.kw.ac.kr`), browser cookie policy blocks cross-origin session
cookies. In that case, login fails around `LoginCaptcha`/`LoginConfirm`.
Use Android/iOS/desktop, or provide a same-origin reverse proxy.

Optional base URL override:

```bash
flutter run --dart-define=KLAS_BASE_URI=https://your-proxy.example.com
```

## Demo Flow

1. Enter student ID and password.
2. Tap `Sign in and load data`.
3. Confirm session info, context list, and task list are shown.
4. Change context from the dropdown and verify task list reload.

## Safety

- Use read-only endpoints only when testing with a real account.
- Never hardcode credentials in source code.
- Do not log student ID, password, token, or cookie values.
