$ErrorActionPreference = "Stop"

Write-Host "Running Flutter quality gate..."

flutter pub get
flutter analyze
flutter test --coverage

Write-Host "Quality gate passed."
