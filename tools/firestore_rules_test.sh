#!/usr/bin/env bash
set -euo pipefail

echo "Running Firestore security rules tests..."

npm install --prefix firestore_rules_tests
npm --prefix firestore_rules_tests test

echo "Firestore security rules tests finished."
