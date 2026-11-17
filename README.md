<p align="center">
  <img src=".github/shadowgram.png" width="128" height="128" alt="Shadowgram">
</p>

<h1 align="center">Shadowgram для iPhone</h1>

<p align="center">
  Неофициальный клиент Telegram с режимом призрака, сохранением удалённых сообщений и десятками настроек.<br>
  <a href="https://github.com/andrygasanov-netizen/shadowgram/releases/latest"><b>Скачать последнюю версию</b></a> ·
  <a href="https://github.com/andrygasanov-netizen/shadowgram-android">Android</a> ·
  <a href="https://github.com/andrygasanov-netizen/shadowgram-desktop">Windows</a> ·
  <a href="#english">English</a>
</p>

> Shadowgram не связан с Telegram FZ-LLC и Swiftgram. Это независимый форк с открытым исходным кодом.
> Основан на [Swiftgram](https://github.com/Swiftgram/Telegram-iOS), а тот — на официальном [Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS).

## Содержание

- [Установка](#установка)
- [Возможности](#возможности)
- [Уведомления](#уведомления)
- [Частые вопросы](#частые-вопросы)
- [Сборка](#сборка)
- [Лицензия и благодарности](#лицензия-и-благодарности)

## Установка

1. Скачайте `Shadowgram.ipa` со страницы [последнего релиза](https://github.com/andrygasanov-netizen/shadowgram/releases/latest).
2. Подпишите и установите его через **Feather**, **ESign**, **Sideloadly** или **AltStore**.
3. Откройте Shadowgram и войдите в свой аккаунт Telegram, как в обычном приложении.

IPA публикуется без подписи: у проекта нет аккаунта разработчика Apple, поэтому подписать его нужно самостоятельно.

## Возможности

Все настройки собраны в одном месте: **Настройки → Shadowgram Tools**.
Для быстрого старта откройте **Основные настройки** и нажмите **«Включить рекомендуемое»**: включатся удалённые сообщения, исчезающие медиа, история правок, скрытый просмотр историй и безлимитные закрепы.

### Режим призрака 👻

| Функция | Что делает |
|---|---|
| Не отправлять «прочитано» | Собеседник не видит, что вы прочитали сообщение |
| Не показывать «печатает…» | Набор текста не виден |
| Не показывать «в сети» | Вы остаётесь «был(а) недавно», пока не отправите сообщение |
| Скрытый просмотр историй | Истории смотрятся без отметки о просмотре |
| Быстрый переключатель | Включает и выключает всё сразу с главной страницы Tools |

### Чаты

- **Удалённые сообщения.** Сообщения, которые собеседник удалил у всех, остаются в чате с меткой 🗑. Сохраняется то, что приложение успело получить.
- **Исчезающие медиа.** Одноразовые фото, видео и голосовые приходят как обычные с меткой 🔥: их можно пересматривать и сохранять.
- **История правок.** Зажмите отредактированное сообщение → «История правок», чтобы увидеть прошлые версии.
- **Блокировка чатов.** Зажмите чат в списке → «Заблокировать чат»: он откроется только по Face ID, Touch ID или коду телефона.
- **Скрытые чаты.** Зажмите чат → «Скрыть чат». Скрытые чаты открываются из Shadowgram Tools → «Скрытые чаты».
- **Безлимитные закрепы.** Закрепляйте сколько угодно чатов. Закрепы сверх лимита Telegram хранятся на устройстве.
- **Папки админа.** Папки «Мои группы» и «Мои каналы» с чатами, где вы владелец или администратор.
- **Авто-принятие заявок** на вступление в ваши группы и каналы.
- **Напоминания о непрочитанном** через выбранное время после выхода из приложения.
- Настройка списка чатов, профилей и меню, которое открывается по нажатию на сообщение.

### Сообщения

- **Стиль текста** для всех исходящих сообщений: жирный, курсив, подчёркнутый, зачёркнутый, моноширинный или спойлер.
- **Авто-постфикс:** свой текст в конце каждого сообщения.
- **Эффект сердечка ❤️** на отправленных сообщениях в личных чатах.
- **Авто-стикер:** после текстового сообщения отправляется последний использованный стикер.
- Редактирование двойным тапом, «Сохранить в Избранное» в меню сообщения.
- Перевод сообщений и расшифровка голосовых без Telegram Premium.

### Интерфейс

- **Плашка у Dynamic Island** «⚡ SHADOWGRAM»: пять цветов или скрыть совсем (Tools → Интерфейс).
- **Цветные иконки Shadowgram** в стиле настроек Telegram.
- Вкладки, папки, истории, цвета аккаунтов, секунды во времени сообщений.
- ID, дата-центр и дата регистрации в профиле, подтверждение перед звонком.

### Медиа и загрузки

- **Отключить автозагрузку** фото, видео и файлов по мобильной сети и Wi-Fi.
- Качество отправляемых фото, отправка фото в большом размере, кружки на заднюю камеру.
- Ускорение загрузки и отправки файлов.

## Уведомления

Push-уведомления Apple работают только в приложениях, подписанных ключом владельца, поэтому в переподписанном IPA их нет. В Shadowgram есть два способа это обойти:

1. **Мгновенные уведомления через ntfy.** Установите бесплатное приложение [ntfy](https://apps.apple.com/app/ntfy/id1625396347), затем в Shadowgram: Tools → Чаты → «Мгновенные уведомления» → «Подписаться в ntfy». Telegram будет сообщать о новых сообщениях на ваш личный канал ntfy, а ntfy покажет уведомление.
2. **Фоновая проверка.** iOS сама периодически будит Shadowgram и показывает уведомление, если появились непрочитанные. Это бесплатно, но с задержкой, которую выбирает система.

## Частые вопросы

**Это безопасно? Мои сообщения куда-то уходят?**
Нет. Shadowgram подключается напрямую к серверам Telegram, как официальное приложение. Удалённые сообщения, история правок и скрытые чаты хранятся только на вашем телефоне. Исходный код открыт.

**Почему не получается сменить иконку из приложения?**
iOS не даёт переподписанным приложениям менять собственную иконку (ошибка -54). Выберите иконку в Feather при подписи. Готовые картинки есть в релизах и в папке `.github`.

**Меня забанят за режим призрака?**
Shadowgram просто не отправляет некоторые служебные запросы («прочитано», «печатает»). Сервер Telegram видит обычного клиента.

**Сохраняются ли сообщения, удалённые до установки?**
Нет. Сохраняется только то, что приложение успело получить, пока было установлено.

## Сборка

IPA собирается через GitHub Actions: workflow **Build Shadowgram IPA** (`.github/workflows/build.yml`), запуск вручную. Поле `version` задаёт номер релиза (например, `13.2.1.1`), а описание берётся из `.github/RELEASE_NOTES.md`.

```sh
gh workflow run build.yml --ref master -f version=13.2.1.1
```

Для сборки нужны секреты репозитория:

| Секрет | Что это |
|---|---|
| `API_ID` | api_id приложения с [my.telegram.org](https://my.telegram.org/apps) |
| `API_HASH` | api_hash того же приложения |

Локальная сборка на macOS выполняется так же, как сборка официального приложения: [руководство Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS#readme).

## Лицензия и благодарности

Код распространяется под лицензией **GNU GPL v2**, как и исходный Telegram iOS. Весь исходный код Shadowgram открыт в этом репозитории.

Спасибо [Telegram](https://github.com/TelegramMessenger/Telegram-iOS) и [Swiftgram](https://github.com/Swiftgram/Telegram-iOS), на которых построен Shadowgram.

---

<a id="english"></a>

# Shadowgram for iPhone (English)

An unofficial Telegram client with ghost mode, saved deleted messages and dozens of extra settings. Based on [Swiftgram](https://github.com/Swiftgram/Telegram-iOS), which is based on the official [Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS). Not affiliated with Telegram FZ-LLC or Swiftgram.

## Install

1. Download `Shadowgram.ipa` from the [latest release](https://github.com/andrygasanov-netizen/shadowgram/releases/latest).
2. Sign and install it with **Feather**, **ESign**, **Sideloadly** or **AltStore** (the IPA is unsigned).
3. Open Shadowgram and log in to your Telegram account.

## Features

Everything is in **Settings → Shadowgram Tools**. Open **Essentials** and tap **"Turn on recommended"** for a quick start.

- **Ghost mode:** no read receipts, no "typing…", no online status, story stealth mode, one switch for all.
- **Chats:** deleted messages kept with a 🗑 mark, view-once media kept (🔥), edit history, chats locked with Face ID, hidden chats, unlimited pins, admin folders, auto-approve join requests, unread reminders.
- **Messages:** text style for every message, auto-postfix, heart effect, auto-sticker, double tap to edit, "Save to Saved Messages", translation and voice transcription without Premium.
- **Interface:** "⚡ SHADOWGRAM" badge by the Dynamic Island (five colours or hidden), Shadowgram icons, seconds in message time, profile ID, data center and registration date, call confirmation.
- **Media:** turn off auto-download, outgoing photo quality, large photos, rear camera for video messages, faster uploads and downloads.

## Notifications

Apple push notifications only work in apps signed with the owner's key, so a re-signed IPA has none. Shadowgram offers two workarounds:

1. **Instant notifications via ntfy:** install the free [ntfy](https://apps.apple.com/app/ntfy/id1625396347) app, then Shadowgram Tools → Chats → "Instant notifications" → "Subscribe in ntfy".
2. **Background check:** iOS wakes Shadowgram from time to time and shows a notification for new unread messages.

## Build

Builds run on GitHub Actions (`.github/workflows/build.yml`, manual run with a `version` input). The repository needs the `API_ID` and `API_HASH` secrets from [my.telegram.org](https://my.telegram.org/apps).

## License

GNU GPL v2, like Telegram iOS. Thanks to [Telegram](https://github.com/TelegramMessenger/Telegram-iOS) and [Swiftgram](https://github.com/Swiftgram/Telegram-iOS).
