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

Флоу такой:
1. ставишь базовый OpenClaw
2. проходишь `openclaw onboard`
3. запускаешь `openclaw-zm/setup.sh`
4. setup накатывает наш workspace/persona/skills поверх OpenClaw
5. рестартуешь gateway и работаешь уже в нашем флоу

### 1. Поставить OpenClaw

Следуй официальному репо OpenClaw:
https://github.com/openclaw/openclaw

После установки обязательно выполни:

```bash
openclaw onboard
```

Это создаст и настроит базовый `~/.openclaw`.

### 2. Накатить openclaw-zm

Можно держать это репо где угодно, setup сам поставит нужные файлы в правильные папки.

```bash
git clone git@github.com:PrivetAI/openclaw-zm.git ~/Desktop/apps/openclaw-zm
bash ~/Desktop/apps/openclaw-zm/setup.sh
openclaw gateway restart
```

После этого создай новую сессию с агентом.

### Что делает setup.sh

`setup.sh` приводит OpenClaw к нашему рабочему состоянию:
- копирует в `~/.openclaw/workspace/`:
  - `AGENTS.md`
  - `SOUL.md`
  - `IDENTITY.md`
  - `HEARTBEAT.md`
  - `TOOLS.md`
  - `setup.sh`
  - `README.md`
- синхронизирует `skills/` в `~/.openclaw/workspace/skills/`
- перезаписывает agent/persona файлы из репо, чтобы бот точно был в нужной конфигурации
- перезаписывает bot/persona/tooling файлы из репо, включая `TOOLS.md`
- **не трогает память пользователя**:
  - `MEMORY.md`
  - `memory/`
- создаёт `USER.md`, если его ещё нет
- генерирует `config/paths.json`
- патчит `~/.openclaw/openclaw.json`
- добавляет `hooks.internal.entries.bootstrap-extra-files.paths`, чтобы OpenClaw явно подхватывал persona/context файлы

### Важно

- setup рассчитан на уже установленный OpenClaw после `openclaw onboard`
- локальные persona/agent/tooling files в workspace будут заменены версией из этого репо
- память и журнал агента сохраняются
- после setup нужен **`openclaw gateway restart`** и **новая сессия**

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
