---
name: project-scaffold
description: Генерує мінімальний кросплатформний Hello World-проєкт на Python 3.10+ — структуру src/hello_world, tests, README.md, .gitignore, pyproject.toml (з конфігурацією pytest), requirements.txt і requirements-dev.txt. Використовується командою create-project і оркестратором init.
---

# Skill: project-scaffold

## 1. Призначення

Навичка застосовується, коли потрібно створити початкову структуру Python-проєкту: на етапі `create-project` (`@prompts/create-project.prompt.md`) або як другий крок оркестратора `init` після `git-init`. Вона створює мінімальний Hello World: пакет `src/hello_world/` (src-layout) з функціями `greet()`, `add()` і точкою входу `main()`, каталог модульних тестів `tests/` з обов'язковими `test_greet()` і `test_basic_addition()`, початковий `.gitignore`, `pyproject.toml` з конфігурацією `pytest`, `requirements.txt` і `requirements-dev.txt`, а також генерує або оновлює `README.md` з описом проєкту та командами запуску.

Навичка не створює `.venv`, не встановлює залежності й не запускає тести — це робить `skills/build-and-test`.

## 2. Вхідні дані (Inputs)

- **Мова:** Python 3.10+ (мінімальна версія записується в `requires-python`).
- **Назва модуля:** `hello_world` (валідний ідентифікатор Python: малі літери, цифри, `_`, не починається з цифри).
- **Цільова директорія:** корінь репозиторію (`.`); усі шляхи нижче відносні до неї.

## 3. Очікувані результати (Outputs)

Створювані файли:

```text
.
├── src/
│   └── hello_world/
│       ├── __init__.py
│       └── main.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
├── README.md
└── .gitignore
```

**Структура пакета.** Використовується src-layout: код пакета лежить у `src/hello_world/`, тому тести імпортують саме пакет, а не випадкові файли з кореня. Код використовує лише стандартну бібліотеку і не містить шляхів чи викликів, прив'язаних до ОС.

`src/hello_world/__init__.py`:

```python
"""Hello World package."""

__version__ = "0.1.0"
```

`src/hello_world/main.py`:

```python
"""Entry point for the Hello World application."""


def greet() -> str:
    return "Hello, World!"


def add(a: int, b: int) -> int:
    return a + b


def main() -> None:
    print(greet())


if __name__ == "__main__":
    main()
```

`tests/__init__.py` — порожній файл (0 байт, без переносу рядка).

`tests/test_main.py` містить обов'язкові тести `test_greet()` і `test_basic_addition()` (BasicAddition):

```python
from hello_world.main import add, greet, main


def test_greet():
    assert greet() == "Hello, World!"


def test_basic_addition():
    assert add(2, 3) == 5


def test_main_prints_greeting(capsys):
    main()
    assert capsys.readouterr().out.strip() == "Hello, World!"
```

**Конфігурація pytest у `pyproject.toml`.** `testpaths` обмежує пошук тестів каталогом `tests/`, а `pythonpath = ["src"]` дозволяє `pytest` імпортувати `hello_world` без ручного налаштування `PYTHONPATH` на будь-якій ОС:

```toml
[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"

[project]
name = "hello_world"
version = "0.1.0"
description = "Cross-platform Hello World project"
requires-python = ">=3.10"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
addopts = "-v"
```

`requirements.txt` — runtime-залежності (для Hello World порожній, лише коментар):

```text
# Runtime dependencies
```

`requirements-dev.txt`:

```text
-r requirements.txt
pytest>=7.0
```

`.gitignore`:

```text
.venv/
__pycache__/
*.pyc
.pytest_cache/
build/
dist/
*.egg-info/
```

`README.md` містить опис проєкту і команди запуску. Якщо файл уже існує (наприклад, з даними власника), агент не перезаписує його, а лише дописує відсутні розділи «Опис» і «Запуск»:

````markdown
# hello_world

Мінімальний кросплатформний Hello World-проєкт на Python 3.10+ (src-layout, venv, pytest).

## Запуск

Linux / macOS:

```bash
./scripts/ci.sh                      # створити .venv, встановити залежності, запустити pytest
PYTHONPATH=src python3 -m hello_world.main
```

Windows (cmd):

```bat
scripts\ci.bat
set PYTHONPATH=src && python -m hello_world.main
```
````

## 4. Команди перевірки (Verification)

Після генерації агент перевіряє наявність усіх файлів, синтаксис Python, коректність `pyproject.toml` і запуск програми. Будь-яка ненульова відповідь означає провал етапу.

Linux / macOS:

```bash
for f in src/hello_world/__init__.py src/hello_world/main.py \
         tests/__init__.py tests/test_main.py \
         pyproject.toml requirements.txt requirements-dev.txt README.md .gitignore; do
  test -f "$f" || { echo "[FAIL] Missing: $f"; exit 1; }
done
python3 -m py_compile src/hello_world/__init__.py src/hello_world/main.py tests/test_main.py
python3 -c "import sys; sys.version_info >= (3, 11) and __import__('tomllib').load(open('pyproject.toml', 'rb'))"
PYTHONPATH=src python3 -m hello_world.main
```

Windows (cmd):

```bat
for %%f in (src\hello_world\__init__.py src\hello_world\main.py tests\__init__.py tests\test_main.py pyproject.toml requirements.txt requirements-dev.txt README.md .gitignore) do (
  if not exist "%%f" (echo [FAIL] Missing: %%f & exit /b 1)
)
python -m py_compile src\hello_world\__init__.py src\hello_world\main.py tests\test_main.py || exit /b 1
python -c "import sys; sys.version_info >= (3, 11) and __import__('tomllib').load(open('pyproject.toml', 'rb'))" || exit /b 1
set PYTHONPATH=src
python -m hello_world.main || exit /b 1
```

`py_compile` перевіряє синтаксис без запуску коду. Перевірка `pyproject.toml` через `tomllib` виконується лише на Python 3.11+, а на 3.10 вираз коротко замикається на `False` і завершується з кодом 0 без `ModuleNotFoundError`. Запуск `python -m hello_world.main` має вивести `Hello, World!`; `PYTHONPATH=src` потрібен, бо до створення `.venv` пакет ще не встановлено.

## 5. Типові сценарії помилок (Error Handling)

**Python відсутній або застарілий.** Перед генерацією агент перевіряє інтерпретатор: `python3 --version` на Linux/macOS, `python --version` або `py -3 --version` на Windows. Якщо команда не знайдена або версія нижча за 3.10, агент зупиняє етап за принципом fail-fast, не створює жодних файлів і повідомляє користувачу:

```text
[FAIL] Етап: create-project
Причина: Python 3.10+ не знайдено (виявлено: <версія або "відсутній">)
Що зробити: встановіть Python 3.10+ і перезапустіть @prompts/create-project.prompt.md
```

**Конфлікт з уже існуючими файлами.** Навичка ідемпотентна. Якщо файл уже існує і його вміст збігається з шаблоном, агент пропускає його. Якщо файл існує, але відрізняється (наприклад, користувач змінив `main.py`), агент не перезаписує його і не видаляє, а повідомляє про конфлікт і просить підтвердження. Для `.gitignore` агент лише дописує відсутні рядки, не змінюючи наявних; для `README.md` — лише відсутні розділи опису та запуску. Якщо при цьому бракує обов'язкових елементів (немає `greet()`, `add()` або тестів `test_greet()` / `test_basic_addition()`), агент вказує, чого саме бракує, і пропонує точкову правку замість повного перезапису.

**Некоректна назва модуля або цільова директорія.** Якщо назва модуля не є валідним ідентифікатором Python або цільова директорія не існує чи лежить поза репозиторієм, агент зупиняється і просить користувача виправити вхідні дані.

**Провал перевірки.** Якщо після генерації бракує файлу, `py_compile` повертає помилку або `python -m hello_world.main` завершується з ненульовим кодом, етап вважається проваленим: агент показує назву файлу і текст помилки інтерпретатора, а оркестратор `init` не переходить до `create-build`.
