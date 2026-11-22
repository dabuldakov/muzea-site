#!/usr/bin/env bash
# Переносит подписанный APK из приватного репозитория приложения в публичный
# muzea-site и на хостинг сайта. Сайт и автообновление читают метаданные
# релиза из GitHub, а сам APK скачивают с https://muzea.su/downloads/.
#
# Использование:
#   FTP_HOST=31.31.196.115 FTP_USER=... FTP_PASSWORD=... \
#     ./scripts/promote-release.sh v1.7.55
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

APK_FILE="$(find "$TMP" -maxdepth 1 -type f -name '*.apk' | head -1)"
[[ -n "$APK_FILE" ]] || { echo "!! в релизе нет APK" >&2; exit 1; }

NOTES="$TMP/release-notes.md"
if gh release view "$TAG" -R "$APP_REPO" --json body -q .body > "$NOTES" 2>/dev/null && [ -s "$NOTES" ]; then
  echo "==> заметки взяты из приватного релиза"
else
  echo "muzea $VERSION" > "$NOTES"
fi

echo "==> публикую $TAG в $SITE_REPO"
gh release create "$TAG" "$APK_FILE" \
  -R "$SITE_REPO" \
  --title "muzea $VERSION" \
  --notes-file "$NOTES" \
  --latest

if [[ -n "${FTP_HOST:-}" && -n "${FTP_USER:-}" && -n "${FTP_PASSWORD:-}" ]]; then
  FTP_DIR="${FTP_DIR:-/www/muzea.su/downloads}"
  echo "==> загружаю APK на $FTP_HOST:$FTP_DIR"
  curl -sS --ftp-create-dirs --user "$FTP_USER:$FTP_PASSWORD" \
    -T "$APK_FILE" "ftp://$FTP_HOST$FTP_DIR/muzea-$VERSION.apk"
  echo "==> APK: https://muzea.su/downloads/muzea-$VERSION.apk"
else
  echo "!! FTP_HOST/FTP_USER/FTP_PASSWORD не заданы — APK не попал на сайт" >&2
  echo "   Сайт и приложение будут искать /downloads/muzea-$VERSION.apk" >&2
fi

echo "==> готово: https://github.com/$SITE_REPO/releases/tag/$TAG"
