# Gym Routine Planner

A simple flutter app to plan your gym routine for the week.

- Uses firebase as a backend for authentication and storing the data.
- Supports only Android for now because I don't have a Mac to test it on iOS.

## Getting Started

1. Clone the repo

```bash
git clone https://github.com/DanielCaz/gym_routine_planner.git
```

2. Install dependencies

```bash
flutter pub get
```

3. Enjoy!

## Requirements

You have to import the `google-services.json` file into the `android/app` folder. You can get it from the firebase console.

Also create firestore_options.dart file in the `lib` folder, more info [here](https://firebase.flutter.dev/docs/overview/#initializing-flutterfire).

## Credits

App icon from [icons8](https://icons8.com/).
