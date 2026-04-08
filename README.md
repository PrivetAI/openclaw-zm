# openclaw-zm

iOS dev addon для [OpenClaw](https://github.com/openclaw/openclaw). Скиллы, инструменты и флоу для автоматизированной сборки приложений.

## Что делает

AI-агент по текстовому описанию:
1. Генерирует идеи приложений
2. Создаёт Xcode-проекты с полным UI
3. Интегрирует WebView с redirect-трекером
4. Тестирует в симуляторе
5. Готовит к отправке в App Store через Codemagic

## Установка

**Сначала поставь OpenClaw:** https://github.com/openclaw/openclaw

Дальше есть два нормальных сценария.

### Вариант A, рекомендованный: клонировать репо прямо в workspace

```bash
git clone git@github.com:PrivetAI/openclaw-zm.git ~/.openclaw/workspace
bash ~/.openclaw/workspace/setup.sh
nano ~/.openclaw/workspace/USER.md
openclaw gateway restart
```

После этого создай новую сессию с агентом.

### Вариант B: ручной перенос файлов в `~/.openclaw/workspace`

Если ты уже распаковал или склонировал репо в другую папку, можно просто перенести файлы вручную в `~/.openclaw/workspace`, а затем запустить setup из исходной папки репо или из самого workspace.

Пример:

```bash
# файлы репо уже скопированы в ~/.openclaw/workspace
bash ~/.openclaw/workspace/setup.sh
nano ~/.openclaw/workspace/USER.md
openclaw gateway restart
```

Важно:
- setup теперь считает workspace валидным, даже если там нет папки `skills/.git` в старом виде
- setup автоматически патчит `~/.openclaw/openclaw.json`
- он добавляет `hooks.internal.entries.bootstrap-extra-files.paths`, чтобы OpenClaw явно подхватывал persona/context файлы
- после setup нужен **restart gateway** и **новая сессия**, иначе старый контекст может остаться в памяти текущего запуска

setup.sh проверит/установит:
- Xcode (проверка)
- GitHub CLI (`gh`)
- XcodeBuildMCP (тестирование в симуляторе)
- Рабочие директории
- `USER.md` + `config/paths.json`
- `bootstrap-extra-files` в `~/.openclaw/openclaw.json`

## Архитектура

```
~/.openclaw/workspace/        ← этот репо
├── AGENTS.md                 ← правила агента
├── SOUL.md                   ← личность
├── IDENTITY.md               ← имя
├── HEARTBEAT.md              ← периодические задачи
├── setup.sh                  ← установка
├── skills/                   ← навыки (14 шт)
│   ├── ios-builder/          ← сборка приложений
│   ├── ios-tester/           ← тестирование
│   ├── ios-app-rename/       ← переименование
│   ├── ios-version-bump/     ← бамп версий
│   ├── codemagic/            ← CI/CD
│   ├── idea-gen/             ← генерация идей
│   └── ...
│
│   Локальные (gitignored):
├── USER.md                   ← данные владельца
├── config/paths.json         ← пути
├── memory/                   ← логи агента
└── MEMORY.md                 ← долгосрочная память
```

## Флоу

```
Тема + Бренд → Идеи → Утверждение → Сборка → Тест → Доставка
                 ↓         ↓            ↓        ↓        ↓
             idea-gen   Telegram   ios-builder  Sim   for_human_review_apps/
                                       ↓
                                  Sub-agents (параллельно)
```

1. Даёшь тему — бренд, палитра, категория
2. Агент генерирует идеи, ты утверждаешь
3. Sub-agents строят приложения параллельно
4. Готовые → `for_human_review_apps/` → GitHub → Codemagic → App Store

## Технические требования

- iOS 15.6+ (без iOS 16+ API)
- Custom UI — без SF Symbols, без emoji
- Manual signing, `UILaunchScreen` обязателен
- WebView с RedirectTracker в каждом приложении

## Команды

```
"3 приложения, тема казино, бренд Lucky, палитра: красный + золотой"
"переименуй App Name в New Name, домен newname.org"
"бамп билд номер для AppName"
"настрой codemagic для AppName"
```
