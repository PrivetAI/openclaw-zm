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
├── USER.md.example       ← шаблон — скопировать в USER.md
├── TOOLS.md.example      ← шаблон — скопировать в TOOLS.md
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
│   Создаются локально (не в репо):
├── config/               ← paths.json, mcporter.json
├── memory/               ← дневные логи агента
├── MEMORY.md             ← долгосрочная память
├── USER.md               ← данные владельца
└── TOOLS.md              ← заметки по инструментам
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

# Создаём конфиг
cp config.example.yaml config.yaml
# Редактируем config.yaml — вставляем токены:
#   - Anthropic API key
#   - Telegram bot token + allowed users
#   - GitHub token (опционально)
```

### 3. Workspace (этот репо)

```bash
# Клонируем workspace
cd ~/.openclaw
git clone git@github.com:PrivetAI/openclaw-zm.git workspace
cd workspace

# Создаём локальные файлы из шаблонов
cp USER.md.example USER.md
cp TOOLS.md.example TOOLS.md

# Создаём config/paths.json под свой мак
mkdir -p config
cat > config/paths.json << EOF
{
  "development": "/Users/$(whoami)/Documents/development",
  "review_apps": "/Users/$(whoami)/Documents/development/for_human_review_apps",
  "old_apps": "/Users/$(whoami)/Documents/development/old_apps",
  "skills": "/Users/$(whoami)/Desktop/openclaw/skills",
  "app_descriptions": "/Users/$(whoami)/Documents/development/for_human_review_apps/APP_DESCRIPTIONS.md"
}
EOF

# Редактируем USER.md под себя
nano USER.md
```

### 4. Запуск

```bash
cd ~/Desktop/openclaw
node openclaw.mjs gateway start
```

## Конфигурация

### Локальные файлы (не в репо)

| Файл | Назначение | Создание |
|------|-----------|----------|
| `USER.md` | Данные владельца | `cp USER.md.example USER.md` |
| `TOOLS.md` | Заметки по инструментам | `cp TOOLS.md.example TOOLS.md` |
| `config/paths.json` | Пути к директориям | setup.sh создаёт автоматически |
| `config/mcporter.json` | MCP-серверы | Создать при необходимости |
| `memory/` | Дневные логи | Создаётся агентом |
| `MEMORY.md` | Долгосрочная память | Создаётся агентом |

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
