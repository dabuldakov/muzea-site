#!/usr/bin/env bash
# Публикует подписанный APK из релиза приложения:
#   1) заливает его на хостинг сайта (https://muzea.su/downloads/);
#   2) создаёт архивный релиз в публичном muzea-site.
#
# Метаданные для сайта и автообновления берутся из релиза в публичном
# dabuldakov/muzea, который создаёт workflow Release. Этот скрипт нужен,
# чтобы файл был доступен по быстрому адресу на сайте.
#
# Использование:
#   APK=path/to/app-release.apk \
#   FTP_HOST=31.31.196.115 FTP_USER=... FTP_PASSWORD=... \
#     ./scripts/promote-release.sh v1.7.55
#
# Без APK скрипт скачает ассет из релиза (может быть медленно).
set -euo pipefail

TAG="${1:?использование: promote-release.sh v1.7.55}"
APP_REPO="${APP_REPO:-dabuldakov/muzea}"
SITE_REPO="${SITE_REPO:-dabuldakov/muzea-site}"
SITE_URL="${SITE_URL:-https://muzea.su}"
VERSION="${TAG#v}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -n "${APK:-}" ]]; then
  APK_FILE="$APK"
  [[ -f "$APK_FILE" ]] || { echo "!! APK не найден: $APK_FILE" >&2; exit 1; }
  echo "==> использую локальный APK: $APK_FILE"
else
  echo "==> скачиваю $TAG из $APP_REPO"
  gh release download "$TAG" -R "$APP_REPO" -p '*.apk' -D "$TMP"
  APK_FILE="$(find "$TMP" -maxdepth 1 -type f -name '*.apk' | head -1)"
  [[ -n "$APK_FILE" ]] || { echo "!! в релизе нет APK" >&2; exit 1; }
fi

ASSET="$TMP/muzea-$VERSION.apk"
[[ "$APK_FILE" == "$ASSET" ]] || cp "$APK_FILE" "$ASSET"

if [[ -n "${FTP_HOST:-}" && -n "${FTP_USER:-}" && -n "${FTP_PASSWORD:-}" ]]; then
  FTP_DIR="${FTP_DIR:-/www/muzea.su/downloads}"
  echo "==> загружаю APK на $FTP_HOST:$FTP_DIR"
  curl -sS --ftp-create-dirs --user "$FTP_USER:$FTP_PASSWORD" \
    -T "$ASSET" "ftp://$FTP_HOST$FTP_DIR/muzea-$VERSION.apk"

  URL="$SITE_URL/downloads/muzea-$VERSION.apk"
  SIZE="$(stat -c %s "$ASSET")"
  echo "==> проверяю $URL"
  REMOTE_SIZE="$(curl -sSI --max-time 30 "$URL" | awk 'tolower($1)=="content-length:" {gsub("\\r",""); print $2}')"
  if [[ "$REMOTE_SIZE" != "$SIZE" ]]; then
    echo "!! размер на сайте ($REMOTE_SIZE) не совпадает с APK ($SIZE)" >&2
    exit 1
  fi
  echo "==> APK доступен: $URL ($SIZE байт)"
elif [[ "${SKIP_FTP:-0}" != "1" ]]; then
  echo "!! FTP_HOST/FTP_USER/FTP_PASSWORD не заданы — APK не попал на сайт" >&2
  echo "   Для архивации без загрузки: SKIP_FTP=1 $0 $TAG" >&2
  exit 1
fi

NOTES="$TMP/release-notes.md"
if gh release view "$TAG" -R "$APP_REPO" --json body -q .body > "$NOTES" 2>/dev/null && [ -s "$NOTES" ]; then
  echo "==> заметки взяты из релиза $APP_REPO"
else
  echo "muzea $VERSION" > "$NOTES"
fi

echo "==> создаю архивный релиз $TAG в $SITE_REPO"
gh release create "$TAG" "$ASSET" \
  -R "$SITE_REPO" \
  --title "muzea $VERSION" \
  --notes-file "$NOTES" \
  --latest

echo "==> готово: https://github.com/$SITE_REPO/releases/tag/$TAG"
