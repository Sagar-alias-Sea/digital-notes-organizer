# Digital Notes Organizer

A simple Flutter notes app for capturing and organizing everyday thoughts. Built with Dart and Flutter, with a calm, card-based interface and easy navigation.

## Features

- Browse notes in a two-column card layout
- Search note titles, content, and categories
- Filter notes by Personal, Work, or Journal
- Pin notes for quick access
- Create, edit, and delete notes
- Choose a note color
- Save notes on device with `shared_preferences`
- Sample notes included on first launch

## Run locally

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone this repository.
3. From the project folder, run:

   ```sh
   flutter pub get
   flutter run
   ```

## Verify

```sh
flutter analyze
flutter test
```

## GitHub

In VS Code, open the Source Control view, choose **Publish to GitHub**, sign in if prompted, and select **Public repository**. VS Code will create the repository and push the project. If you prefer the terminal, first create an empty repository on github.com, then run:

```sh
git remote add origin https://github.com/YOUR_USERNAME/REPOSITORY_NAME.git
git push -u origin main
```

## Publish a web demo

The project can run as a Flutter web app. For a public demo link, deploy it as a static site on Vercel or Render using the GitHub repository:

1. Build command: `git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter && /tmp/flutter/bin/flutter build web`
2. Output / publish directory: `build/web`

The deployment service creates a public URL after the build finishes. Note data is stored in each browser locally and does not sync between devices.
