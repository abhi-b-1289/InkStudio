#!/usr/bin/env bash
set -euo pipefail

AVD_NAME="inkstudio_avd"
SYSTEM_IMAGE="system-images;android-35;google_apis;x86_64"

LOG_DIR="/tmp/inkstudio-logs"
mkdir -p "${LOG_DIR}"

log() { echo "==> $*"; }

rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

log "Starting virtual display (Xvfb on :99)..."
Xvfb :99 -screen 0 1280x800x24 &>${LOG_DIR}/xvfb.log &
sleep 2

log "Starting window manager (fluxbox)..."
fluxbox &>${LOG_DIR}/fluxbox.log &
sleep 1

log "Starting VNC server (x11vnc, port 5900)..."
x11vnc -display :99 -forever -shared -nopw -rfbport 5900 &>${LOG_DIR}/x11vnc.log &
sleep 1

log "Starting noVNC web bridge (port 6080)..."
websockify --web=/opt/novnc 6080 localhost:5900 &>${LOG_DIR}/websockify.log &
sleep 1

if [ ! -d "${HOME}/.android/avd/${AVD_NAME}.avd" ]; then
  log "No AVD found — creating '${AVD_NAME}'..."
  echo "no" | avdmanager create avd \
    --name "${AVD_NAME}" \
    --package "${SYSTEM_IMAGE}" \
    --force
else
  log "Reusing existing AVD '${AVD_NAME}'."
fi

rm -rf /tmp/android-*/emu-crash-*.db

log "Starting Android emulator..."
emulator -avd "${AVD_NAME}" \
  -no-boot-anim \
  -gpu swiftshader_indirect \
  -no-snapshot-load \
  -crash-report-mode disabled \
  -accel on \
  &>${LOG_DIR}/emulator.log &

log "Waiting for emulator to boot (this can take a couple of minutes on first run)..."
timeout 360 adb wait-for-device || true
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 2
done
log "Emulator boot complete."

if [ -f /workspace/melos.yaml ]; then
  cd /workspace

  if find app packages -name pubspec.yaml 2>/dev/null | grep -q .; then
    log "Running melos bootstrap..."
    melos bootstrap
    log "Running code generation (Riverpod/Drift/Freezed/JSON)..."
    melos exec -- "dart run build_runner build --delete-conflicting-outputs" || true
  else
    log "No workspace packages yet — skipping bootstrap. Scaffold the monorepo, then rerun: docker compose restart"
  fi
fi

cat <<EOF

------------------------------------------------------------
InkStudio dev environment ready.

  noVNC (view emulator in browser): http://localhost:6080/vnc.html
  adb devices:                      should list 'emulator-5554'
  hot reload:                       cd app && flutter run -d emulator-5554

------------------------------------------------------------

EOF

exec "$@"
