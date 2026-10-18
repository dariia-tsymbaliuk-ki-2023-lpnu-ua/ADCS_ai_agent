---
name: build-and-test
description: Ізолює середовище розробки у .venv, встановлює pytest, забезпечує модульні тести (test_greet, test_basic_addition) і генерує уніфіковані кросплатформні скрипти збірки scripts/ci.sh та scripts/ci.bat. Використовується командами create-build, check і оркестратором init.
---

# Skill: build-and-test

## 1. Призначення

Навичка застосовується після `skills/project-scaffold`: на етапі `create-build` (`@prompts/create-build.prompt.md`), на етапі `check` і як третій крок оркестратора `init`. Вона ізолює середовище розробки у віртуальному середовищі `.venv`, встановлює туди `pytest`, забезпечує наявність модульних тестів і генерує два уніфіковані скрипти збірки: `scripts/ci.sh` для Linux/macOS і `scripts/ci.bat` для Windows. Обидва скрипти виконують однакову послідовність кроків, і саме їх викликає як розробник локально, так і GitHub Actions, тому результат збірки однаковий на всіх ОС.

## 2. Вхідні дані (Inputs)

- **Вихідний код:** пакет `src/hello_world/` з `__init__.py` і `main.py` (функції `greet()`, `add()`, `main()`), а також `pyproject.toml` з `[tool.pytest.ini_options]` — створюються навичкою `project-scaffold`.
- **Модуль `venv`:** доступний у Python 3.10+ (`python3 -m venv --help` / `python -m venv --help`). На Debian/Ubuntu може знадобитися пакет `python3-venv`.
- **`pip`:** доступний як `python -m pip`; після створення `.venv` використовується лише `pip` із середовища.

## 3. Очікувані результати (Outputs)

```text
.
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── requirements-dev.txt
├── scripts/
│   ├── ci.sh        # Linux / macOS, виконуваний (chmod +x)
│   └── ci.bat       # Windows
└── .venv/           # створюється скриптом, у Git не комітиться
```

Якщо тести й `requirements-dev.txt` уже створено навичкою `project-scaffold`, агент лише перевіряє, що в них є обов'язкові елементи, і не перезаписує файли (ідемпотентність).

### `tests/__init__.py` і `tests/test_main.py`

`tests/__init__.py` — порожній файл. `tests/test_main.py` містить обов'язкові тести `test_greet()` і BasicAddition (`test_basic_addition()`):

```python
from hello_world.main import add, greet


def test_greet():
    assert greet() == "Hello, World!"


def test_basic_addition():
    assert add(2, 3) == 5
```

### `requirements-dev.txt`

```text
-r requirements.txt
pytest>=7.0
```

### `scripts/ci.sh` (Linux / macOS)

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PYTHON="${PYTHON:-python3}"
VENV_PY=".venv/bin/python"

command -v "$PYTHON" >/dev/null 2>&1 || { echo "[FAIL] $PYTHON not found"; exit 1; }

if [ ! -x "$VENV_PY" ]; then
  echo "[INFO] Creating virtual environment .venv"
  "$PYTHON" -m venv .venv
fi

"$VENV_PY" -m pip install --upgrade pip
"$VENV_PY" -m pip install -r requirements-dev.txt

"$VENV_PY" -m pytest
PYTHONPATH=src "$VENV_PY" -m hello_world.main

echo "[OK] Build and tests passed"
```

`set -euo pipefail` зупиняє скрипт на першій помилці (`-e`), на зверненні до неоголошеної змінної (`-u`) і на помилці будь-якої команди в конвеєрі (`pipefail`). Інтерпретатор із `.venv` викликається за повним шляхом, тому активація середовища не потрібна. Файл зберігається з закінченнями рядків LF, а після створення агент обов'язково робить його виконуваним:

```bash
chmod +x scripts/ci.sh
git update-index --chmod=+x scripts/ci.sh   # зберегти біт виконання в Git
```

### `scripts/ci.bat` (Windows)

```bat
@echo off
setlocal

cd /d "%~dp0.."

set "VENV_PY=.venv\Scripts\python.exe"

where python >nul 2>&1
if errorlevel 1 (
  echo [FAIL] python not found
  exit /b 1
)

if not exist "%VENV_PY%" (
  echo [INFO] Creating virtual environment .venv
  python -m venv .venv
  if errorlevel 1 exit /b 1
)

"%VENV_PY%" -m pip install --upgrade pip
if errorlevel 1 exit /b 1

"%VENV_PY%" -m pip install -r requirements-dev.txt
if errorlevel 1 exit /b 1

"%VENV_PY%" -m pytest
if errorlevel 1 exit /b 1

set "PYTHONPATH=src"
"%VENV_PY%" -m hello_world.main
if errorlevel 1 exit /b 1

echo [OK] Build and tests passed
exit /b 0
```

Після кожної команди `if errorlevel 1 exit /b 1` реалізує той самий принцип fail-fast, що й `set -e` у `ci.sh`. Файл зберігається з закінченнями рядків CRLF.

## 4. Команди перевірки (Verification)

Агент запускає скрипт під поточну ОС і перевіряє, що код повернення дорівнює 0, а у виводі є `Hello, World!`, результат `pytest` з `test_greet` і `test_basic_addition` у статусі `PASSED` та рядок `[OK] Build and tests passed`.

Linux / macOS:

```bash
./scripts/ci.sh
echo "Exit code: $?"      # очікується 0
```

Windows (cmd):

```bat
scripts\ci.bat
echo Exit code: %errorlevel%
```

Повторний запуск має також завершуватися з кодом 0 і не створювати `.venv` заново — це перевірка ідемпотентності.

## 5. Типові сценарії помилок (Error Handling)

У всіх випадках агент працює за принципом fail-fast: зупиняє етап, не переходить до `create-actions` і повідомляє користувачу етап, причину, ключовий фрагмент виводу та дію для виправлення.

**Падіння тестів (`AssertionError`).** `pytest` повертає ненульовий код, і скрипт зупиняється. Агент показує назву тесту й рядок перевірки з виводу, наприклад `tests/test_main.py::test_basic_addition FAILED — assert 6 == 5`, і пропонує виправити код у `src/hello_world/main.py` або сам тест. Агент не видаляє й не пропускає тести (`skip`, `xfail`), щоб «зазеленити» збірку.

```text
[FAIL] Етап: create-build
Причина: pytest завершився з кодом 1
Деталі: tests/test_main.py::test_basic_addition FAILED — AssertionError: assert 6 == 5
Що зробити: виправте add() у src/hello_world/main.py і перезапустіть ./scripts/ci.sh
```

**`Permission denied` для `ci.sh`.** Виникає, якщо файл не має біта виконання (наприклад, після клонування на Linux/macOS). Агент виконує `chmod +x scripts/ci.sh` і `git update-index --chmod=+x scripts/ci.sh`, після чого перезапускає скрипт. Як тимчасовий обхід можна запустити `bash scripts/ci.sh`. Якщо помилка `bad interpreter` спричинена закінченнями рядків CRLF, агент повідомляє про це і пропонує перезберегти файл з LF.

**Збій завантаження пакетів через `pip`.** Причини: немає мережі, недоступний PyPI або проксі, неіснуюча версія пакета, помилка SSL. Агент показує повідомлення `pip` (наприклад, `Could not find a version that satisfies the requirement`), перевіряє, що `requirements-dev.txt` не містить помилок у назвах і версіях, і пропонує перевірити мережу або проксі та перезапустити скрипт. Агент не встановлює пакети в глобальний інтерпретатор і не використовує `sudo` як обхід.

**Відсутній `venv` або `pip`.** Якщо `python -m venv` падає з `ensurepip is not available`, агент повідомляє, що потрібно встановити `python3-venv` (Debian/Ubuntu) або перевстановити Python з `pip`, і зупиняється.
