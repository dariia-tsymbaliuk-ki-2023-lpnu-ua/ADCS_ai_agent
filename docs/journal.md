# Журнал взаємодії з AI

## Запис 1 — 18.10.2026

**Запит.** Створити базову документацію та маніфест агента Build Engineer (Варіант 2: Python, `venv`, `pytest`): `README.md` з даними власника, описом проєкту та інструкцією запуску, `docs/architecture.md` з описом архітектури агента і маніфест `build-engineer.agent.md` з роллю, областю відповідальності, правилами роботи з файлами, забороненими діями та критеріями Definition of Done.

**Рішення.** Архітектуру адаптовано під клієнт Cursor замість GitHub Copilot. Агент запускається в Cursor Composer (режим Agent) через виклик `@prompts/init.prompt.md`. Маніфест агента оформлено як правило Cursor `.cursor/rules/build-engineer.mdc` з `alwaysApply: true`, тож він автоматично підключається до кожного запиту; окремий файл `.github/agents/build-engineer.agent.md` прибрано. Навички розміщено в `skills/`, команди — як prompt-файли в `prompts/`. У `docs/architecture.md` описано відповідність каталогів Copilot → Cursor, а таблиці замінено на блоки для кращої читабельності.

**Результат перевірки студентом.** Файли створені коректно: `README.md`, `docs/architecture.md`, `.cursor/rules/build-engineer.mdc`.

## Запис 2 — 18.10.2026 (Етап 2: skills)

**Запит.** Створити три навички агента у форматі `skills/<name>/SKILL.md`, кожна з розділами «Призначення», «Вхідні дані», «Очікувані результати», «Команди перевірки» та «Типові сценарії помилок». `project-scaffold` генерує мінімальний Hello World у src-layout (`src/hello_world/` з `greet()`, `add()`, `main()`), тести, `README.md`, `.gitignore`, `pyproject.toml` з конфігурацією `pytest` і файли залежностей. `build-and-test` ізолює середовище у `.venv`, встановлює `pytest` і генерує кросплатформні скрипти `scripts/ci.sh` (`set -euo pipefail`, `chmod +x`) та `scripts/ci.bat` (перевірка `errorlevel`). `github-actions` створює `.github/workflows/ci.yml` з тригерами `push` / `pull_request` у `develop`, `master`, `main`. Під час роботи окремими запитами уточнено перевірку `pyproject.toml` через `tomllib` для сумісності з Python 3.10, додано перевірку запуску `python -m hello_world.main` і заперечення `! grep` для пошуку заборонених викликів у workflow.

**Рішення.** Логіку збірки повністю відокремлено у скрипти `scripts/ci.sh` і `scripts/ci.bat`: вони створюють `.venv`, встановлюють залежності й запускають `pytest`, а `ci.yml` не містить прямих викликів `pip` чи `pytest` і лише запускає відповідний скрипт. Тому локальна збірка і CI виконують ту саму послідовність. Тест BasicAddition (`test_basic_addition()`) обов'язковий поруч із `test_greet()` і перевіряє базову логіку функції `add()`. CI підтримує матрицю трьох ОС (`ubuntu-latest`, `windows-latest`, `macos-latest`) з `fail-fast: false`, а скрипт під ОС вибирається умовою `if: runner.os`, щоб `ci.sh` ніколи не запускався на Windows. Усі навички працюють за принципами fail-fast та ідемпотентності.

**Результат перевірки студентом.** Структура каталогів `skills/` створена коректно (`skills/project-scaffold/SKILL.md`, `skills/build-and-test/SKILL.md`, `skills/github-actions/SKILL.md`), усі файли валідні та відповідають вимогам.

## Запис 3 — 18.10.2026 (Етап 3: команди та оркестратор)

**Запит.** Створити в `prompts/` п'ять команд — `git-init`, `create-project`, `create-build`, `create-actions`, `check` — та оркестратор `init`. Кожен prompt-файл має розділи Prerequisites, Actions, Expected Files, Verification, Error Handling і дотримується ідемпотентності. `git-init` перевіряє стан Git, доповнює `.gitignore` і виводить `git status --short`; `create-project`, `create-build` і `create-actions` виконують відповідні навички; `check` лише діагностує проєкт і повертає звіт `[OK]` / `[FAIL]`; `init` запускає всі етапи в порядку `git-init → create-project → create-build → create-actions → check`. Окремими запитами уточнено: матрицю `python-version: ["3.10", "3.12"]` і `with: python-version` у `create-actions`, безпечний виклик `yamllint` та PyYAML (попередження `[WARN]` замість аварійного завершення), перевірку обох скриптів `scripts\ci.bat` і `scripts\ci.sh` у `create-build` та `tests\__init__.py` у `py_compile` для Windows у `check`.

**Рішення.** Оркестратор `init` реалізує принцип fail-fast: на першій помилці зупиняється, не запускає наступні етапи і виводить етап, причину, діагностичний фрагмент виводу та інструкцію для виправлення; уже створені файли не відкочуються. Команда `check` залишається суто діагностичною (read-only): не створює й не змінює файли, не виконує `chmod` і git-операції із записом, запускає `ci.sh` через `bash` і порівнює знімки `git status --porcelain` до і після перевірки. Усі команди посилаються на навички відносними шляхами (`skills/<name>/SKILL.md`) і викликають одна одну через `@prompts/<name>.prompt.md`, тому агент не залежить від розташування репозиторію на диску.

**Результат перевірки студентом.** Усі prompt-файли (`prompts/git-init.prompt.md`, `prompts/create-project.prompt.md`, `prompts/create-build.prompt.md`, `prompts/create-actions.prompt.md`, `prompts/check.prompt.md`, `prompts/init.prompt.md`) валідні, відповідають структурі та готові до виконання.

## Запис 4 — 18.10.2026 (Етап 4: генерація проєкту та виправлення помилок)

**Запит.** Створити гілку `feature/ai-agent-setup` і запустити повний цикл оркестрації через `@prompts/init.prompt.md` у Cursor Composer (режим Agent): `git-init → create-project → create-build → create-actions → check`.

**Рішення.** Під час тестового запуску `scripts/ci.sh` на етапі `create-build` виник збій `Permission denied` (п. 7.8 методички): згенерований скрипт не мав біта виконання. Оркестратор зупинився за принципом fail-fast і вивів етап, причину та рекомендацію. Агент виправив помилку командою `chmod +x scripts/ci.sh` і зберіг біт виконання в індексі Git через `git update-index --chmod=+x scripts/ci.sh`, щоб скрипт залишався виконуваним після клонування на Linux/macOS. Після виправлення етап `create-build` і наступні етапи виконано повторно без руйнування вже створених файлів.

**Результат перевірки студентом.** Локальний запуск `./scripts/ci.sh` завершився з кодом 0: `pytest` показав `3 passed`, включно з `test_basic_addition`, програма вивела `Hello, World!`. Каталог `.venv/` і кеші (`__pycache__/`, `.pytest_cache/`) ігноруються Git.

## Запис 5 — 18.10.2026 (Етап 5: публікація та матричний CI у GitHub Actions)

**Запит.** Відправити гілки `develop` і `feature/ai-agent-setup` у віддалений репозиторій GitHub і відкрити Pull Request `lab1/finish` → `develop`.

**Рішення.** Матричний пайплайн у `.github/workflows/ci.yml` налаштовано на 3 ОС (`ubuntu-latest`, `windows-latest`, `macos-latest`) і 2 версії Python (`3.10`, `3.12`), тобто 6 комбінацій. Кроки збірки суворо делеговано скриптам відповідно до `runner.os`: на Linux і macOS викликається `bash scripts/ci.sh`, на Windows — `scripts\ci.bat`. Інлайн-викликів `pip` чи `pytest` у workflow немає, тож CI виконує ту саму послідовність, що й локальна збірка.

**Результат перевірки студентом.** У Pull Request успішно пройдено всі 6 перевірок (`All checks have passed`), зокрема `scripts\ci.bat` успішно виконано на Windows-раннері.

## Запис 6 — 18.10.2026 (Етап 6: перевірка та аналіз репозиторію)

**Запит.** Провести діагностику репозиторію через `@prompts/check.prompt.md`, перевірити ідемпотентність повторним викликом `@prompts/init.prompt.md` і виконати аудит репозиторію.

**Рішення.** Підтверджено, що команда `check` працює в режимі read-only: знімки `git status --porcelain` до і після перевірки однакові. Повторний запуск `init` на вже налаштованому проєкті не спотворив і не продублював конфігурацій (`.gitignore`, `README.md`, `requirements-dev.txt`, `ci.yml`), усі етапи завершилися зі статусом `[OK]`. Аудит підтвердив відсутність токенів, паролів і секретів у коді, скриптах і workflow.

**Результат перевірки студентом.** Команда `check` повернула `RESULT: [OK]`. Перевірка `git status --ignored` підтверджує, що `.venv/` і кеші перебувають у списку ігнорованих, робоче дерево чисте.
