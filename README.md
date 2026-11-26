# muzea-site

Публичный сайт `muzea.su` и площадка для Android-сборок.

## Что здесь лежит

| Путь | Назначение |
|---|---|
| `index.html` | главная (русская) |
| `en/` | английская версия |
| `privacy/`, `terms/`, `delete-account/` | юридические страницы |
| `icon-512.png`, `icon-512.webp` | иконки |
| `lang.js` | переключатель языка |

Сайт статический, без сборки. Хостинг — reg.ru, docroot `www/muzea.su`,
загрузка по FTP.

## Android-релизы

Метаданные последнего релиза (версия, заметки, наличие APK) сайт и приложение
берут из **публичного репозитория приложения**:

```
https://api.github.com/repos/dabuldakov/muzea/releases/latest
```

Сам APK скачивается с нашего хостинга:

```
https://muzea.su/downloads/muzea-<version>.apk
```

Приложение проверяет обновления по манифесту:

```
https://muzea.su/version.json
```

`version.json` содержит `version`, `downloadUrl` и `changelog`; его создаёт
`scripts/promote-release.sh` вместе с загрузкой APK. GitHub Releases остаётся
fallback-каналом для старых сборок и истории.

Так быстрее: GitHub Releases в РФ отдаёт файлы ~10 КБ/с, а сайт — сотни КБ/с.

Workflow `Release` в `dabuldakov/muzea` собирает подписанные APK/AAB и
публикует релиз — это и есть источник метаданных для сайта и приложения.
После сборки APK нужно положить на хостинг, а для архива — приложить к релизу
в этом репозитории:

```bash
APK=../muzea/app/build/outputs/apk/release/app-release.apk \
FTP_HOST=31.31.196.115 FTP_USER=... FTP_PASSWORD=... \
  ./scripts/promote-release.sh v1.7.55
```

Скрипт:

1. берёт локальный APK (или скачивает из релиза, если `APK` не задан);
2. заливает его в `/www/muzea.su/downloads/muzea-<version>.apk`;
3. создаёт архивный релиз в `muzea-site` (для истории, обновления его не читают);
4. проверяет, что APK доступен по HTTPS.

Требования:

- APK подписан тем же keystore, что и предыдущие версии, иначе Android не
  установит обновление поверх;
- `versionCode` больше предыдущего, тег — `v<versionName>`;
- релиз в `dabuldakov/muzea` должен быть **Latest**;
- файл на сайте должен появиться до того, как пользователи начнут обновляться,
  иначе приложение получит 404.

Сайт кэширует ответ GitHub API на 10 минут, приложение проверяет обновления
при запуске.

### Переход на скачивание с сайта

Сборки до `1.7.54` включительно качают APK прямо из GitHub Releases. Это
работает, пока `dabuldakov/muzea` публичный. В `1.7.55` добавлено скачивание
с `muzea.su`, поэтому после обновления файлы будут браться с сайта.
Метаданные в обоих случаях — из публичного `dabuldakov/muzea`.

## iPhone

iOS распространяется через TestFlight (закрытое тестирование по email).
Сайт не обращается к GitHub API для iOS, поэтому приватность
`dabuldakov/muzea-ios` на него не влияет.

## Публикация сайта по FTP

В корне репозитория лежит ровно то, что должно оказаться в `www/muzea.su`.
Учётные данные FTP в репозиторий не попадают.

```bash
# пример: загрузить только изменённые страницы
curl --user "$FTP_USER:$FTP_PASSWORD" -T index.html   ftp://31.31.196.115/www/muzea.su/index.html
curl --user "$FTP_USER:$FTP_PASSWORD" -T en/index.html   ftp://31.31.196.115/www/muzea.su/en/index.html
```

После загрузки проверить `https://muzea.su/` и `https://muzea.su/en/`.

## Секреты

В репозитории не должно быть паролей, токенов, keystore и `.env`.
