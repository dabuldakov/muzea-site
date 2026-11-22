(function () {
  var KEY = 'muzea.lang';

  var RU_TIMEZONES = [
    'Europe/Kaliningrad', 'Europe/Moscow', 'Europe/Simferopol',
    'Europe/Volgograd', 'Europe/Saratov', 'Europe/Astrakhan',
    'Europe/Ulyanovsk', 'Europe/Kirov', 'Europe/Samara',
    'Asia/Yekaterinburg', 'Asia/Omsk', 'Asia/Novosibirsk', 'Asia/Barnaul',
    'Asia/Tomsk', 'Asia/Novokuznetsk', 'Asia/Krasnoyarsk', 'Asia/Irkutsk',
    'Asia/Chita', 'Asia/Yakutsk', 'Asia/Khandyga', 'Asia/Vladivostok',
    'Asia/Ust-Nera', 'Asia/Magadan', 'Asia/Sakhalin', 'Asia/Srednekolymsk',
    'Asia/Kamchatka', 'Asia/Anadyr'
  ];

  function inRussia() {
    try {
      var tz = Intl.DateTimeFormat().resolvedOptions().timeZone || '';
      return RU_TIMEZONES.indexOf(tz) !== -1;
    } catch (e) {
      return false;
    }
  }

  function currentLang() {
    var lang = (document.documentElement.getAttribute('lang') || 'ru').toLowerCase();
    return lang.indexOf('en') === 0 ? 'en' : 'ru';
  }

  // Сервер отдаёт каталоги с завершающим слэшем (/terms/), а канонические
  // адреса — без него. Убираем слэш, иначе английская версия документа
  // уводит на лендинг, а русская версия /en/delete-account — на главную.
  function normalize(path) {
    return path.length > 1 ? path.replace(/\/+$/, '') : path;
  }

  function ruToEn(path) {
    path = normalize(path);
    if (/^\/privacy(\.html)?$/.test(path)) return '/en/privacy';
    if (/^\/terms(\.html)?$/.test(path)) return '/en/terms';
    if (/^\/delete-account(\.html)?$/.test(path)) return '/en/delete-account';
    return '/en/';
  }

  function enToRu(path) {
    path = normalize(path);
    var rest = path.replace(/^\/en(?=\/|$)/, '');
    if (/^\/(privacy|terms|delete-account)(\.html)?$/.test(rest)) {
      return rest.replace(/\.html$/, '');
    }
    return '/';
  }

  function target(lang) {
    var path = location.pathname;
    return lang === 'en' ? ruToEn(path) : enToRu(path);
  }

  var ua = navigator.userAgent || '';
  var isBot = /bot|crawl|spider|slurp|googlebot|bingbot|yandex|duckduck|baiduspider/i.test(ua);
  if (isBot) return;

  var query = location.search.match(/[?&]lang=(ru|en)(?:&|$)/);
  var stored = null;
  try { stored = localStorage.getItem(KEY); } catch (e) {}

  var lang;
  if (query) lang = query[1];
  else if (stored === 'ru' || stored === 'en') lang = stored;
  else lang = inRussia() ? 'ru' : 'en';

  if (lang !== currentLang()) {
    var dest = target(lang);
    if (dest && dest !== location.pathname) location.replace(dest);
  }

  document.addEventListener('click', function (e) {
    var el = e.target;
    while (el && el !== document) {
      if (el.hasAttribute && el.hasAttribute('data-lang')) {
        try { localStorage.setItem(KEY, el.getAttribute('data-lang')); } catch (err) {}
        return;
      }
      el = el.parentNode;
    }
  });
})();
