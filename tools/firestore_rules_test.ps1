$ErrorActionPreference = "Stop"

Write-Host "Running Firestore security rules tests..."

npm install --prefix firestore_rules_tests
npm --prefix firestore_rules_tests test

Write-Host "Firestore security rules tests finished."
