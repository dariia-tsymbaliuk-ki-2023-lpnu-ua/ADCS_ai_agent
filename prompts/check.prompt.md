---
description: Діагностика без змін проєкту — перевіряє структуру, валідність YAML, запускає скрипт збірки під поточну ОС і повертає звіт [OK] / [FAIL].
---

# Команда: check

Ти — Build & Automation Engineer (див. `.cursor/rules/build-engineer.mdc`). Виконай діагностику проєкту і поверни звіт.

> **Сувора вимога: команда НЕ ЗМІНЮЄ проєкт.** Заборонено створювати, редагувати, перейменовувати чи видаляти файли, виконувати `chmod`, `git add`, `git commit` та будь-які інші git-операції із записом. Якщо щось не так — лише зафіксуй `[FAIL]` і порекомендуй команду для виправлення. Єдиний дозволений побічний ефект — створення або оновлення `.venv/` скриптом збірки: це ігнорований Git артефакт, а не частина проєкту.

## Prerequisites

- Виконано етапи `git-init`, `create-project`, `create-build`, `create-actions` (або проєкт створено вручну з тією самою структурою).
- Доступні `git`, Python 3.10+ та PyYAML або `yamllint`.

## Actions

1. Зафіксуй стан репозиторію до перевірки: `git status --porcelain` (знімок A).
2. **Структура.** Перевір наявність файлів зі списку Expected Files і обов'язкових елементів: `greet`, `add`, `main` у `src/hello_world/main.py`; `test_greet`, `test_basic_addition` у `tests/test_main.py`; правила `.venv/`, `__pycache__/`, `.pytest_cache/`, `*.pyc`, `build/`, `dist/` у `.gitignore`.
3. **Синтаксис.** `python -m py_compile` для файлів у `src/` і `tests/`.
4. **YAML.** Валідація `.github/workflows/ci.yml`, наявність трьох runner у матриці, кроків запуску `scripts/ci.sh` / `scripts\ci.bat` і відсутність прямих викликів `pip` / `pytest`.
5. **Збірка.** Запуск скрипта під поточну ОС: `bash scripts/ci.sh` (Linux/macOS; через `bash`, щоб не змінювати права файлу) або `scripts\ci.bat` (Windows). Перевір код повернення 0.
6. Зафіксуй стан після перевірки: `git status --porcelain` (знімок B). Якщо A ≠ B — це `[FAIL]` порушення вимоги «не змінювати проєкт».
7. Виведи діагностичний звіт (формат нижче). Перевірки виконуй усі, навіть якщо одна з них провалилась, щоб звіт був повним; загальний статус — `[FAIL]`, якщо провалено хоча б один пункт.

## Expected Files

```text
.gitignore
README.md
pyproject.toml
requirements.txt
requirements-dev.txt
src/hello_world/__init__.py
src/hello_world/main.py
tests/__init__.py
tests/test_main.py
scripts/ci.sh
scripts/ci.bat
.github/workflows/ci.yml
```

## Verification

Linux / macOS:

```bash
before=$(git status --porcelain)
for f in .gitignore README.md pyproject.toml requirements.txt requirements-dev.txt \
         src/hello_world/__init__.py src/hello_world/main.py tests/__init__.py tests/test_main.py \
         scripts/ci.sh scripts/ci.bat .github/workflows/ci.yml; do
  test -f "$f" && echo "[OK]   $f" || echo "[FAIL] Missing: $f"
done
python3 -m py_compile src/hello_world/*.py tests/*.py && echo "[OK]   Python syntax"
if python3 -c "import yaml" 2>/dev/null; then
  python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "[OK]   YAML syntax"
else
  echo "[WARN] PyYAML not installed, skipping YAML parsing"
fi
! grep -nwE 'pip|pytest' .github/workflows/ci.yml && echo "[OK]   ci.yml calls only scripts/ci.*"
bash scripts/ci.sh && echo "[OK]   scripts/ci.sh exit code 0"
[ "$before" = "$(git status --porcelain)" ] && echo "[OK]   Project unchanged" || echo "[FAIL] Project was modified"
```

Windows (cmd):

```bat
git status --porcelain > "%TEMP%\check_before.txt"
for %%f in (.gitignore README.md pyproject.toml requirements.txt requirements-dev.txt src\hello_world\__init__.py src\hello_world\main.py tests\__init__.py tests\test_main.py scripts\ci.sh scripts\ci.bat .github\workflows\ci.yml) do (
  if exist "%%f" (echo [OK]   %%f) else (echo [FAIL] Missing: %%f)
)
python -m py_compile src\hello_world\__init__.py src\hello_world\main.py tests\__init__.py tests\test_main.py && echo [OK]   Python syntax
python -c "import yaml" 2>nul
if errorlevel 1 (
  echo [WARN] PyYAML not installed, skipping YAML parsing
) else (
  python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo [OK]   YAML syntax
)
call scripts\ci.bat && echo [OK]   scripts\ci.bat exit code 0
git status --porcelain > "%TEMP%\check_after.txt"
fc /b "%TEMP%\check_before.txt" "%TEMP%\check_after.txt" >nul && echo [OK]   Project unchanged || echo [FAIL] Project was modified
```

Тимчасові файли зберігаються в `%TEMP%`, поза проєктом.

Формат звіту:

```text
=== check report ===
[OK]   Structure: 12/12 files
[OK]   Required functions: greet, add, main
[OK]   Required tests: test_greet, test_basic_addition
[OK]   .gitignore rules
[OK]   Python syntax
[OK]   YAML syntax, matrix: ubuntu-latest, windows-latest, macos-latest
[OK]   ci.yml calls only scripts/ci.sh / scripts/ci.bat
[OK]   Build script (linux): exit code 0
[OK]   Project unchanged
RESULT: [OK]
```

Команда ідемпотентна: повторний запуск дає той самий звіт і не змінює проєкт.

## Error Handling

Кожна невдала перевірка позначається `[FAIL]` з причиною і рекомендованою командою для виправлення; сама команда нічого не виправляє.

- **Відсутній файл** → `[FAIL] Missing: <файл>`; рекомендація: команда етапу, що його створює (`@prompts/create-project.prompt.md`, `@prompts/create-build.prompt.md`, `@prompts/create-actions.prompt.md`).
- **Невалідний YAML або бракує runner** → `[FAIL]` з рядком/колонкою помилки або списком відсутніх runner; рекомендація: `@prompts/create-actions.prompt.md`.
- **Прямий виклик `pip` / `pytest` у `ci.yml`** → `[FAIL]` з номером рядка з `grep`.
- **Скрипт збірки завершився з ненульовим кодом** (падіння тестів, збій `pip`) → `[FAIL]` з кодом повернення і ключовим фрагментом виводу (наприклад, `test_basic_addition FAILED`); рекомендація: виправити код і перезапустити `@prompts/create-build.prompt.md`.
- **Відсутні `git`, Python 3.10+ або PyYAML/`yamllint`** → `[FAIL]` для відповідної перевірки з поясненням, що встановити; решту перевірок виконай.
- **Проєкт змінився під час перевірки** (знімки `git status` різняться) → `[FAIL] Project was modified` зі списком змінених файлів.
