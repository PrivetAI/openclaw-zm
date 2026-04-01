# openclaw-zm

Портативный workspace для автоматизированной сборки iOS-приложений через OpenClaw.

## Что это

AI-агент (Boba 🧋) который по текстовому описанию:
1. Генерирует идеи приложений
2. Создаёт Xcode-проекты с полным UI
3. Интегрирует WebView с redirect-трекером
4. Тестирует в симуляторе
5. Готовит к отправке в App Store через Codemagic

## Архитектура

```
openclaw-zm/              ← этот репо (workspace агента)
├── README.md             ← обзор проекта
├── setup.sh              ← bootstrap скрипт для нового мака
├── AGENTS.md             ← инструкции агенту (как себя вести)
├── SOUL.md               ← личность и тон
├── IDENTITY.md           ← имя, эмодзи
├── USER.md               ← данные владельца (редактировать под себя)
├── TOOLS.md              ← заметки по инструментам
├── HEARTBEAT.md          ← периодические задачи
├── skills/               ← навыки агента
│   ├── ios-builder/      ← генерация + сборка приложений
│   ├── ios-tester/       ← тестирование в симуляторе
│   ├── ios-app-rename/   ← переименование проектов
│   ├── ios-version-bump/ ← бамп версий
│   ├── codemagic/        ← CI/CD настройка
│   ├── github/           ← работа с gh CLI
│   ├── idea-gen/         ← генерация идей
│   ├── apple-hig/        ← гайдлайны Apple
│   └── ...               ← остальные
│
│   Создаются локально (gitignored):
├── config/paths.json     ← пути к директориям (setup.sh генерирует)
├── memory/               ← дневные логи агента
└── MEMORY.md             ← долгосрочная память
```

## Флоу работы

```
Тема + Бренд → Генерация идей → Утверждение → Сборка → Тест → Доставка
                     ↓                ↓            ↓        ↓         ↓
                 idea-gen         Telegram    ios-builder  Simulator  for_human_review_apps/
                                                  ↓
                                            Sub-agents (параллельно)
```

### Подробнее

1. **Даёшь тему** — бренд, палитра, категория, количество приложений
2. **Агент генерирует идеи** — проверяет уникальность, предлагает список
3. **Утверждаешь** — можешь поправить названия/фичи
4. **Агент запускает sub-agents** — каждый строит одно приложение параллельно
5. **Каждый sub-agent:**
   - Создаёт Xcode-проект
   - Пишет весь Swift-код (custom UI, без SF Symbols)
   - Интегрирует WebView с RedirectTracker
   - Билдит и проверяет в симуляторе
   - Делает скриншоты
6. **Готовые приложения** → `for_human_review_apps/`
7. **После ревью** → push на GitHub → Codemagic → App Store

### WebView паттерн

Каждое приложение содержит скрытый WebView:
- `RedirectTracker` следит за цепочкой редиректов
- Если конечный URL содержит check-домен → показать приложение
- Иначе → показать WebView на весь экран

### Технические требования

- **iOS 15.6+** (никаких iOS 16+ API)
- Custom UI — без SF Symbols, без emoji
- Английский (US) только
- Manual signing в Xcode
- `UILaunchScreen` dict обязателен в Info.plist
- Адаптивный layout (iPhone, все размеры)

## Установка на новый Mac

### Быстрый старт

```bash
curl -sL https://raw.githubusercontent.com/PrivetAI/openclaw-zm/main/setup.sh | bash
```

Скрипт автоматически:
- Установит Homebrew, Node.js 22, GitHub CLI, XcodeBuildMCP
- Клонирует OpenClaw в `~/Desktop/openclaw/`
- Клонирует workspace в `~/.openclaw/workspace/`
- Создаст `~/Documents/development/` и поддиректории
- Сгенерирует `config/paths.json` под текущего юзера

### После скрипта (вручную)

```bash
# 1. Xcode — установить из App Store, потом:
xcode-select --install
sudo xcodebuild -license accept

# 2. OpenClaw конфиг — запустить визард:
cd ~/Desktop/openclaw && node openclaw.mjs onboard
# Попросит: Anthropic API key, Telegram bot token, allowed user IDs

# 3. GitHub — авторизация:
gh auth login

# 4. USER.md — отредактировать под себя:
nano ~/.openclaw/workspace/USER.md

# 5. Запуск:
cd ~/Desktop/openclaw && node openclaw.mjs gateway start
```

## Конфигурация

### Файлы в репо (портативные)

| Файл | Назначение |
|------|-----------|
| `AGENTS.md` | Правила поведения агента |
| `SOUL.md` | Личность и тон |
| `IDENTITY.md` | Имя, эмодзи |
| `USER.md` | Данные владельца (отредактировать) |
| `TOOLS.md` | Заметки по инструментам |
| `HEARTBEAT.md` | Периодические задачи |
| `skills/` | Все навыки |

### Создаются локально (gitignored)

| Файл | Назначение | Создание |
|------|-----------|----------|
| `config/paths.json` | Пути к директориям | `setup.sh` |
| `memory/` | Дневные логи | Агент автоматически |
| `MEMORY.md` | Долгосрочная память | Агент автоматически |

### Токены (НЕ хранятся в репо)

- `ANTHROPIC_API_KEY` — в `~/.openclaw/openclaw.json`
- Telegram Bot Token — в `~/.openclaw/openclaw.json`
- GitHub SSH key — `~/.ssh/id_ed25519`

## Команды агенту

Примеры команд в Telegram:

```
# Новый батч
"3 приложения, тема казино, бренд Lucky, палитра: красный + золотой"

# Переименование
"переименуй App Name в New Name, домен newname.org"

# Бамп версии
"бамп билд номер для AppName"

# Codemagic
"настрой codemagic для AppName"
```

## GitHub

- Организация: [PrivetAI](https://github.com/PrivetAI)
- Каждое приложение = отдельный репо
- Именование: `App-Name-Like-This`

## Структура приложения

```
AppName/
├── AppName.xcodeproj/
├── AppName/
│   ├── AppNameApp.swift
│   ├── ContentView.swift
│   ├── Info.plist          ← UILaunchScreen обязателен
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   ├── Views/
│   ├── Models/
│   └── WebView/
│       ├── WebViewContainer.swift
│       └── RedirectTracker.swift
└── codemagic.yaml          ← добавляется перед CI
```
