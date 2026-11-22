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

Кнопка «Скачать для Android» на сайте и автообновление в приложении читают
**последний GitHub Release этого репозитория**:

```
https://api.github.com/repos/dabuldakov/muzea-site/releases/latest
```

Исходники приложения лежат в приватном `dabuldakov/muzea`. Workflow `Release`
собирает подписанные APK/AAB и публикует релиз в приватном репозитории.
Дальше APK переносится сюда вручную:

```bash
# 1. Скачать собранный APK из приватного репозитория
gh release download v1.7.55 -R dabuldakov/muzea -p '*.apk' -D /tmp/muzea-release

# 2. Опубликовать его здесь (тег должен совпадать с versionName)
gh release create v1.7.55 /tmp/muzea-release/muzea-1.7.55.apk \
  -R dabuldakov/muzea-site \
  --title "muzea 1.7.55" \
  --notes "Что изменилось: ..." \
  --latest

# 3. Положить APK на хостинг сайта
curl --user "$FTP_USER:$FTP_PASSWORD" --ftp-create-dirs \
  -T /tmp/muzea-release/muzea-1.7.55.apk \
  "ftp://31.31.196.115/www/muzea.su/downloads/muzea-1.7.55.apk"
```

Или одной командой (публикует релиз и сразу кладёт APK на хостинг сайта):

```bash
FTP_HOST=31.31.196.115 FTP_USER=... FTP_PASSWORD=... \
  ./scripts/promote-release.sh v1.7.55
```

Сайт и приложение берут из GitHub только метаданные (версию и заметки), а сам
APK скачивают с `https://muzea.su/downloads/muzea-<version>.apk` — GitHub
Releases в России отдаёт файлы очень медленно.

Требования:

- имя ассета должно заканчиваться на `.apk` — по этому признаку его находят
  сайт и приложение;
- APK подписан тем же keystore, что и предыдущие версии, иначе Android не
  установит обновление поверх;
- `versionCode` больше предыдущего, тег — `v<versionName>`;
- релиз должен быть отмечен как **Latest**.

Сайт кэширует ответ GitHub API на 10 минут, приложение проверяет обновления
при запуске.

### Важно для старых установок

Сборки до `1.7.54` включительно проверяли релизы в `dabuldakov/muzea`.
После перевода того репозитория в приватные автообновление у них перестанет
находить новые версии. Чтобы перейти на этот репозиторий:

1. Выпустить `1.7.55` с обновлённым `GitHubApi` (путь
   `repos/dabuldakov/muzea-site/...`).
2. Опубликовать APK здесь.
3. Пользователям один раз установить `1.7.55` вручную с сайта; дальше
   автообновление снова работает.

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
