#!/usr/bin/env bash
# Переносит подписанный APK из приватного репозитория приложения в публичный
# muzea-site, откуда его скачивают сайт и автообновление.
#
# Использование:
#   ./scripts/promote-release.sh v1.7.55
#
# Нужен gh, авторизованный с доступом к приватному dabuldakov/muzea.
set -euo pipefail

TAG="${1:?использование: promote-release.sh v1.7.55}"
APP_REPO="${APP_REPO:-dabuldakov/muzea}"
SITE_REPO="${SITE_REPO:-dabuldakov/muzea-site}"
VERSION="${TAG#v}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> скачиваю $TAG из $APP_REPO"
gh release download "$TAG" -R "$APP_REPO" -p '*.apk' -D "$TMP"

NOTES="$TMP/release-notes.md"
if gh release view "$TAG" -R "$APP_REPO" --json body -q .body > "$NOTES" 2>/dev/null && [ -s "$NOTES" ]; then
  echo "==> заметки взяты из приватного релиза"
else
  echo "muzea $VERSION" > "$NOTES"
fi

echo "==> публикую $TAG в $SITE_REPO"
gh release create "$TAG" "$TMP"/*.apk \
  -R "$SITE_REPO" \
  --title "muzea $VERSION" \
  --notes-file "$NOTES" \
  --latest

echo "==> готово: https://github.com/$SITE_REPO/releases/tag/$TAG"
