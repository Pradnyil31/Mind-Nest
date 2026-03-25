#!/usr/bin/env bash
set -euo pipefail

echo "Running Flutter quality gate..."

flutter pub get
flutter analyze
flutter test --coverage

echo "Quality gate passed."
