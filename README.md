# InkStudio

## Project Members

  -----------------------------------------------------------------------------------------------------
  Name          --          Student ID        --      GitHub
  ----------------------- ----------------------- -----------------------------------------------------
  Arnob Mutsuddy          (666-63-01)               [Arnob-Mutsuddy](https://github.com/Arnob-Mutsuddy)

  Abhijeet Barua          (666-63-16)               [abhi-b-1289](https://github.com/abhi-b-1289)

  -----------------------------------------------------------------------------------------------------

InkStudio is an offline-capable, cross-platform vector drawing and
sketching app built with Flutter. It combines freehand drawing tools,
parametric shapes with precise measurement controls, selection and
transform tools, SVG/PNG export, guided drawing practice, and the
gamified **InkQuest** mode.

A prebuilt Android package is included at `InkStudio.apk`.

------------------------------------------------------------------------

## Features

-   **Freehand canvas**: Pen and eraser with adjustable stroke width, a
    quick color palette, recent colors, undo, and redo.
-   **Parametric shapes**: Line, arrow, rectangle, rounded rectangle,
    circle, ellipse, triangle, right triangle, diamond, pentagon,
    hexagon, star, heart, and cross. Shapes support fill/stroke colors
    and exact dimension controls.
-   **Selection & transform**: Multi-select, lasso selection, move,
    resize, rotate, duplicate, group, and ungroup.
-   **Export**: Download drawings as SVG or PNG at 1x, 2x, or 4x
    resolution, with platform-aware download handling for web and native
    targets.
-   **Learn Drawing**: Guided tracing practice for circles, triangles,
    stars, hearts, smileys, and waves, scored by SVG similarity.
-   **InkQuest**: Trace, Copy, and Memory challenge tiers, challenge
    packs, star ratings, coins, XP and levels, daily challenges,
    streaks, achievements, a drawing gallery, and a shop for color packs
    and canvas themes.
-   **Canvas presets**: 1:1, 16:9, 4:3, 3:2, 4:5, 21:9, A4, and US
    Letter, with portrait/landscape toggling and custom ratio detection.
-   **Recent drawings**: In-memory recent drawing list with rename and
    delete actions.
-   **Containerized development**: Docker and Dev Container setup with
    Flutter 3.44.0, the Android SDK and emulator, and a noVNC display.

------------------------------------------------------------------------

## Project Structure

``` text
InkStudio/
├── app/                                  # Flutter application (Melos workspace member)
│   ├── lib/
│   │   ├── main.dart                     # Application entry point
│   │   ├── app.dart                      # MaterialApp and theme setup
│   │   ├── controllers/
│   │   │   └── canvas_controller.dart    # Tools, selection, transforms, undo/redo
│   │   ├── core/
│   │   │   ├── app_constants.dart        # Colors, palette, and UI constants
│   │   │   └── formatters.dart           # Shared formatting helpers
│   │   ├── data/
│   │   │   ├── achievement_catalog.dart  # Achievement definitions
│   │   │   ├── quest_catalog.dart        # Quest challenge packs
│   │   │   ├── quest_references.dart     # Quest reference drawings
│   │   │   └── shop_catalog.dart         # Color packs and canvas themes
│   │   ├── models/
│   │   │   ├── achievement.dart
│   │   │   ├── canvas_item.dart          # Strokes, groups, and shape items
│   │   │   ├── canvas_preset.dart        # Canvas size presets
│   │   │   ├── practice_target.dart      # Learn Drawing targets
│   │   │   ├── quest.dart                # Quest tiers and challenges
│   │   │   ├── saved_drawing.dart
│   │   │   ├── score.dart                # Scores and gallery entries
│   │   │   ├── shape.dart                # Shape types and geometry
│   │   │   └── shop.dart                 # Color packs and themes
│   │   ├── painters/
│   │   │   ├── canvas_painters.dart      # Canvas rendering
│   │   │   ├── practice_painters.dart    # Practice guide rendering
│   │   │   └── quest_painters.dart       # Quest reference rendering
│   │   ├── screens/
│   │   │   ├── opening_page.dart
│   │   │   ├── home_page.dart
│   │   │   ├── canvas_page.dart
│   │   │   ├── learn_drawing_page.dart
│   │   │   └── game/
│   │   │       ├── game_home_page.dart   # InkQuest hub
│   │   │       ├── profile_view.dart     # Player progress and gallery
│   │   │       ├── quest_board_view.dart # Challenge selection
│   │   │       ├── quest_play_page.dart  # Quest drawing and scoring
│   │   │       └── shop_view.dart
│   │   ├── services/
│   │   │   ├── download.dart             # Platform-conditional download export
│   │   │   ├── download_io.dart
│   │   │   ├── download_stub.dart
│   │   │   ├── download_web.dart
│   │   │   ├── png_export.dart            # Raster export at multiple scales
│   │   │   ├── practice_reference.dart    # Practice guide generation
│   │   │   ├── svg_document.dart          # SVG serialization
│   │   │   └── svg_similarity.dart        # Drawing similarity scoring
│   │   ├── state/
│   │   │   ├── drawing_store.dart         # Recent drawings
│   │   │   ├── player_state.dart          # Coins, XP, stars, streaks, unlocks
│   │   │   └── recent_colors_store.dart
│   │   └── widgets/
│   │       ├── canvas/
│   │       │   ├── canvas_size_picker.dart
│   │       │   ├── canvas_widgets.dart
│   │       │   └── color_picker.dart
│   │       ├── common/
│   │       │   └── h_scroll.dart
│   │       ├── game/
│   │       │   ├── game_common.dart
│   │       │   └── inkquest_home_entry.dart
│   │       └── home/
│   │           ├── quick_action_card.dart
│   │           └── recent_card.dart
│   ├── test/
│   │   └── widget_test.dart               # Widget tests
│   ├── android/                           # Android host project, manifests, and icons
│   ├── web/                               # Web host, PWA manifest, and icons
│   ├── analysis_options.yaml
│   └── pubspec.yaml                       # Flutter app package
├── docker/
│   └── dev-entrypoint.sh                  # Xvfb, noVNC, and Android emulator bootstrap
├── .devcontainer/
│   └── devcontainer.json                  # VS Code Dev Container configuration
├── Dockerfile                             # Flutter + Android SDK development image
├── docker-compose.yml                     # Development environment service
├── pubspec.yaml                           # Melos workspace root
├── pubspec.lock
├── run.md                                 # Additional run instructions
├── InkStudio.apk                          # Prebuilt Android package
├── README.md
├── .gitignore
└── .dockerignore
```

Generated and local-only directories such as `.dart_tool/`,
`app/build/`, `app/android/.gradle/`, and `app/android/local.properties`
are omitted above.

------------------------------------------------------------------------

## Getting Started

### Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44.0
    (Dart 3.12 or newer)
-   Android Studio and the Android SDK for Android device/emulator
    targets
-   [Melos](https://melos.invertase.dev/) 8.x (optional, for workspace
    scripts)
-   Docker (optional, for the containerized environment)

### Run Locally

``` bash
git clone https://github.com/abhi-b-1289/InkStudio.git
cd InkStudio/app
flutter pub get
flutter run
```

To run in a desktop browser:

``` bash
flutter run -d chrome
```

### Analyze and Test

``` bash
cd app
flutter analyze
flutter test
```

Or from the repository root with Melos:

``` bash
dart pub global activate melos
melos bootstrap
melos run analyze
melos run test
```

Melos also provides `melos run format`, `melos run clean`, and
`melos run verify` (format, analyze, and test in sequence).

### Docker / Dev Container

Start the development environment, including the Android emulator and
noVNC display:

``` bash
docker compose up --build
```

Open `http://localhost:6080/vnc.html` to view the emulator, then run the
app inside the container:

``` bash
cd app
flutter run -d emulator-5554
```

See [run.md](run.md) for running the web build or a hot-reload web
server through Docker without a local Flutter installation.
