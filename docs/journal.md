# Журнал взаємодії з AI

## Запис 1 — 18.10.2026

**Запит.** Створити базову документацію та маніфест агента Build Engineer (Варіант 2: Python, `venv`, `pytest`): `README.md` з даними власника, описом проєкту та інструкцією запуску, `docs/architecture.md` з описом архітектури агента і маніфест `build-engineer.agent.md` з роллю, областю відповідальності, правилами роботи з файлами, забороненими діями та критеріями Definition of Done.

**Рішення.** Архітектуру адаптовано під клієнт Cursor замість GitHub Copilot. Агент запускається в Cursor Composer (режим Agent) через виклик `@prompts/init.prompt.md`. Маніфест агента оформлено як правило Cursor `.cursor/rules/build-engineer.mdc` з `alwaysApply: true`, тож він автоматично підключається до кожного запиту; окремий файл `.github/agents/build-engineer.agent.md` прибрано. Навички розміщено в `skills/`, команди — як prompt-файли в `prompts/`. У `docs/architecture.md` описано відповідність каталогів Copilot → Cursor, а таблиці замінено на блоки для кращої читабельності.

**Результат перевірки студентом.** Файли створені коректно: `README.md`, `docs/architecture.md`, `.cursor/rules/build-engineer.mdc`.

## Запис 2 — 18.10.2026 (Етап 2: skills)

**Запит.** Створити три навички агента у форматі `skills/<name>/SKILL.md`, кожна з розділами «Призначення», «Вхідні дані», «Очікувані результати», «Команди перевірки» та «Типові сценарії помилок». `project-scaffold` генерує мінімальний Hello World у src-layout (`src/hello_world/` з `greet()`, `add()`, `main()`), тести, `README.md`, `.gitignore`, `pyproject.toml` з конфігурацією `pytest` і файли залежностей. `build-and-test` ізолює середовище у `.venv`, встановлює `pytest` і генерує кросплатформні скрипти `scripts/ci.sh` (`set -euo pipefail`, `chmod +x`) та `scripts/ci.bat` (перевірка `errorlevel`). `github-actions` створює `.github/workflows/ci.yml` з тригерами `push` / `pull_request` у `develop`, `master`, `main`. Під час роботи окремими запитами уточнено перевірку `pyproject.toml` через `tomllib` для сумісності з Python 3.10, додано перевірку запуску `python -m hello_world.main` і заперечення `! grep` для пошуку заборонених викликів у workflow.

**Рішення.** Логіку збірки повністю відокремлено у скрипти `scripts/ci.sh` і `scripts/ci.bat`: вони створюють `.venv`, встановлюють залежності й запускають `pytest`, а `ci.yml` не містить прямих викликів `pip` чи `pytest` і лише запускає відповідний скрипт. Тому локальна збірка і CI виконують ту саму послідовність. Тест BasicAddition (`test_basic_addition()`) обов'язковий поруч із `test_greet()` і перевіряє базову логіку функції `add()`. CI підтримує матрицю трьох ОС (`ubuntu-latest`, `windows-latest`, `macos-latest`) з `fail-fast: false`, а скрипт під ОС вибирається умовою `if: runner.os`, щоб `ci.sh` ніколи не запускався на Windows. Усі навички працюють за принципами fail-fast та ідемпотентності.

**Результат перевірки студентом.** Структура каталогів `skills/` створена коректно (`skills/project-scaffold/SKILL.md`, `skills/build-and-test/SKILL.md`, `skills/github-actions/SKILL.md`), усі файли валідні та відповідають вимогам.
