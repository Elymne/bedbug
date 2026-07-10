#!/usr/bin/env bash
# Reproduit localement les étapes de .github/workflows/ci.yml (hors validation du titre de PR).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "📦 Install dependencies"
flutter pub get

echo "🔍 Analyze code"
flutter analyze --fatal-infos --fatal-warnings

echo "🎨 Check formatting"
dart format --set-exit-if-changed --line-length 120 lib/ test/

echo "🧪 Run tests"
flutter test

echo "✅ CI checks passed"
