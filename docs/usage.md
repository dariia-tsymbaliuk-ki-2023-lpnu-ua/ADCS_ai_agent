# Використання агента Build Engineer

Цей документ описує запуск AI-агента в Cursor Composer, ручну локальну перевірку збірки й тестів та запуск програми `hello_world.main` через віртуальне середовище `.venv`. Усі команди виконуються з кореня репозиторію `ADCS_ai_agent`.

## 1. Запуск AI-агента в Cursor Composer

### 1.1. Відкриття Composer і вибір режиму Agent

1. Відкрийте корінь репозиторію в Cursor: `File → Open Folder...` → каталог `ADCS_ai_agent`.
2. Відкрийте Composer комбінацією `Ctrl + I` (на macOS — `Cmd + I`).
3. У перемикачі режимів у нижній частині поля введення виберіть **Agent**.

### 1.2. Виклик оркестратора `@prompts/init.prompt.md`

1. У полі введення Composer наберіть `@`, почніть вводити `init.prompt.md` і виберіть файл `prompts/init.prompt.md` зі списку.
2. Допишіть команду і натисніть `Enter`:

   ```text
   @prompts/init.prompt.md Запусти повний сценарій створення та перевірки проєкту
   ```

3. Підтверджуйте дії агента (створення файлів, запуск команд), коли він їх запитує.

Оркестратор послідовно виконує етапи `git-init → create-project → create-build → create-actions → check` і завершується підсумковим звітом з рядком `Repository status: READY`. На першій помилці він зупиняється з `[FAIL] init зупинено на кроці <N/5>` і підказкою щодо виправлення.

### 1.3. Виклик діагностики `@prompts/check.prompt.md`

1. У новому чаті Composer (режим **Agent**) наберіть `@` і виберіть `prompts/check.prompt.md`.
2. Допишіть команду і натисніть `Enter`:

   ```text
   @prompts/check.prompt.md Виконай діагностику проєкту
   ```

Діагностика не змінює проєкт: перевіряє структуру, синтаксис Python, YAML workflow, запускає скрипт збірки і повертає звіт, що закінчується рядком `RESULT: [OK]` або `RESULT: [FAIL]`.

## 2. Ручна локальна перевірка збірки та тестів

Скрипти створюють `.venv` (лише за першого запуску), оновлюють `pip`, встановлюють `requirements-dev.txt`, запускають `pytest` і `hello_world.main`.

### 2.1. Linux / macOS

Потрібен Python 3.10+ з модулем `venv` (на Debian/Ubuntu — пакет `python3-venv`).

```bash
./scripts/ci.sh
echo "Exit code: $?"          # очікується 0
```

Якщо виникає `Permission denied`, надайте біт виконання або запустіть через `bash`:

```bash
chmod +x scripts/ci.sh
bash scripts/ci.sh
```

### 2.2. Windows (cmd)

Потрібен Python 3.10+, доступний як `python` у `PATH`.

```bat
scripts\ci.bat
echo Exit code: %errorlevel%
```

### 2.3. Очікуваний результат

```text
tests/test_main.py::test_greet PASSED
tests/test_main.py::test_basic_addition PASSED
Hello, World!
[OK] Build and tests passed
```

## 3. Запуск `hello_world.main` через встановлений `.venv`

Перед цим хоча б раз виконайте `./scripts/ci.sh` або `scripts\ci.bat`, щоб створити `.venv`. Пакет використовує src-layout, тому `PYTHONPATH=src` вказує інтерпретатору, де шукати `hello_world`.

Linux / macOS — інтерпретатор із `.venv` за повним шляхом:

```bash
PYTHONPATH=src .venv/bin/python -m hello_world.main
```

Linux / macOS — з активацією середовища:

```bash
source .venv/bin/activate
PYTHONPATH=src python -m hello_world.main
deactivate
```

Windows (cmd) — інтерпретатор із `.venv` за повним шляхом:

```bat
set PYTHONPATH=src
.venv\Scripts\python.exe -m hello_world.main
```

Windows (cmd) — з активацією середовища:

```bat
.venv\Scripts\activate.bat
set PYTHONPATH=src
python -m hello_world.main
deactivate
```

Очікуваний вивід:

```text
Hello, World!
```
