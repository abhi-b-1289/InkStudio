# InkStudio

InkStudio is an offline-capable, cross-platform vector drawing and sketching application built with Flutter. It combines freehand drawing tools, customizable geometric shapes, interactive gamified quests (InkQuest), and multi-format vector exports.

---

## Features

- **Freehand Canvas**: Smooth vector brush engine with pressure simulation, eraser, undo/redo, and color palettes.
- **Parametric Shapes**: Add and manipulate lines, rectangles, circles, stars, polygons, and custom geometry with exact dimension/measurement controls.
- **Selection & Transform**: Move, scale, duplicate, group/ungroup, and rotate canvas elements with ease.
- **Export Capabilities**:
  - Scalable Vector Graphics (**SVG**) export.
  - Multi-resolution raster export (**PNG** at 1x, 2x HD, and 4x Ultra HD).
- **InkQuest Game Mode**: Built-in gamified drawing practice quests with shape matching, accuracy scoring, achievements, and player progress.
- **Presets & Sizing**: Canvas presets for social media, print, and custom aspect ratios in landscape or portrait.
- **Containerized Environment**: Full Docker and Dev Container configurations included for reproducible development and Android emulator testing.

---

## Architecture Overview

```
InkStudio/
├── app/                  # Main Flutter application package
│   ├── lib/
│   │   ├── controllers/  # State & canvas manipulation controllers
│   │   ├── models/       # Data models (canvas items, shapes, quests)
│   │   ├── painters/     # Custom painters for stroke & shape rendering
│   │   ├── screens/      # Canvas, Home, Learn, and Quest game pages
│   │   ├── services/     # SVG document parser, similarity, PNG export
│   │   └── widgets/      # Canvas controls, tool docks, and game widgets
│   ├── android/          # Native Android configuration & manifests
│   └── web/              # Web entry point and PWA manifests
├── docker/               # Container scripts & dev entrypoints
├── .devcontainer/        # VS Code Remote Container configuration
├── Dockerfile            # Container definition with Flutter & Android SDK
├── docker-compose.yml    # Development environment service definition
└── pubspec.yaml          # Melos workspace configuration
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.12.0)
- Android Studio / Android SDK (for Android device/emulator targets)
- [Melos](https://melos.invertase.dev/) (optional, for workspace scripts)

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/abhi-b-1289/InkStudio.git
   cd InkStudio
   ```

2. Fetch dependencies:
   ```bash
   cd app
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Docker / Dev Container Workflow

You can run the entire development environment (including Android emulator via noVNC) through Docker Compose:

```bash
docker compose up --build
```
Open `http://localhost:6080/vnc.html` in your browser to view the containerized emulator display.
