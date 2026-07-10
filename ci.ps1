# Reproduit localement les étapes de .github/workflows/ci.yml (hors validation du titre de PR).
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

Write-Host "📦 Install dependencies"
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "🔍 Analyze code"
flutter analyze --fatal-infos --fatal-warnings
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "🎨 Check formatting"
dart format --set-exit-if-changed --line-length 120 lib/ test/
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "🧪 Run tests"
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "✅ CI checks passed"
