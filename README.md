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
│
│   Создаются локально (gitignored):
├── config/               ← paths.json, mcporter.json
├── memory/               ← дневные логи агента
└── MEMORY.md             ← долгосрочная память
```

## Флоу работы

```
Тема + Бренд → Генерация идей → Утверждение → Сборка → Тест → Доставка
     ↓              ↓                ↓            ↓        ↓         ↓
  Viktor        idea-gen         Telegram    ios-builder  Simulator  for_human_review_apps/
                                                  ↓
                                            Sub-agents (параллельно)
```

### Подробнее

1. **Viktor даёт тему** — бренд, палитра, категория, количество приложений
2. **Boba генерирует идеи** — проверяет уникальность, предлагает список
3. **Viktor утверждает** — может поправить названия/фичи
4. **Boba запускает sub-agents** — каждый строит одно приложение параллельно
5. **Каждый sub-agent:**
   - Создаёт Xcode-проект
   - Пишет весь Swift-код (custom UI, без SF Symbols)
   - Интегрирует WebView с RedirectTracker
   - Билдит и проверяет в симуляторе
   - Делает скриншоты
6. **Готовые приложения** → `for_human_review_apps/`
7. **После ревью** → push на GitHub (PrivetAI org) → Codemagic → App Store

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

Или вручную:

### 1. Зависимости

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.js 22+
brew install node@22

# GitHub CLI
brew install gh
gh auth login

# Xcode (из App Store, потом:)
xcode-select --install
sudo xcodebuild -license accept

# XcodeBuildMCP (опционально, для UI-тестирования)
brew install nicklama/tap/xcodebuildmcp
```

### 2. OpenClaw

```bash
# Клонируем OpenClaw
cd ~/Desktop
git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install

# Запускаем визард — создаст ~/.openclaw/openclaw.json
node openclaw.mjs onboard
# Визард попросит:
#   - Anthropic API key
#   - Telegram bot token + allowed user IDs
```

### 3. Workspace (этот репо)

```bash
# Клонируем workspace
cd ~/.openclaw
git clone git@github.com:PrivetAI/openclaw-zm.git workspace
cd workspace

# setup.sh создаст config/paths.json и директории автоматически
chmod +x setup.sh
./setup.sh

# Отредактируй USER.md под себя
nano USER.md
```

### 4. Запуск

```bash
cd ~/Desktop/openclaw
node openclaw.mjs gateway start
```

## Конфигурация

### Локальные файлы (gitignored, создаются на каждом маке)

| Файл | Назначение | Создание |
|------|-----------|----------|
| `config/paths.json` | Пути к директориям | `setup.sh` создаёт |
| `config/mcporter.json` | MCP-серверы | Вручную при необходимости |
| `memory/` | Дневные логи | Агент создаёт автоматически |
| `MEMORY.md` | Долгосрочная память | Агент создаёт автоматически |

### Токены (НЕ хранятся в репо)

- `ANTHROPIC_API_KEY` — для Claude (основная модель)
- Telegram Bot Token — в config.yaml OpenClaw
- GitHub SSH key — для push в PrivetAI

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
