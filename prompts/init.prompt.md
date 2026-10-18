---
description: Оркестратор — повний запуск усіх етапів підготовки Python-проєкту в порядку git-init → create-project → create-build → create-actions → check з fail-fast, ідемпотентністю і підсумковим звітом.
---

# Команда: init (оркестратор)

Ти — Build & Automation Engineer (див. `.cursor/rules/build-engineer.mdc`). Автоматично виконай усі етапи підготовки проєкту в чітко визначеному порядку:

```text
git-init → create-project → create-build → create-actions → check
```

Кожен етап виконуй строго за інструкціями його prompt-файлу та відповідної навички в `skills/`. Не пропускай етапи, не змінюй їхній порядок і не переходь до наступного, доки поточний не завершився зі статусом `OK`.

## Prerequisites

- Поточний каталог — корінь проєкту, відкритий у Cursor.
- Доступні `git` і Python 3.10+ з модулями `venv` і `pip`.
- Наявні всі prompt-файли етапів (`prompts/git-init.prompt.md`, `prompts/create-project.prompt.md`, `prompts/create-build.prompt.md`, `prompts/create-actions.prompt.md`, `prompts/check.prompt.md`) і навички `skills/project-scaffold/SKILL.md`, `skills/build-and-test/SKILL.md`, `skills/github-actions/SKILL.md`.

Якщо будь-якої передумови немає — зупинись до старту першого етапу (див. Error Handling).

## Actions

Перед кожним кроком виводь заголовок `=== [N/5] <етап> ===`, після кроку — `[OK] <етап>` або `[FAIL] <етап>`.

**Крок 1 — git-init.** Виконай `@prompts/git-init.prompt.md`: перевір стан Git, за потреби `git init`, ідемпотентно доповни `.gitignore`, виведи `git status --short`.

**Крок 2 — create-project.** Виконай `@prompts/create-project.prompt.md` (навичка `skills/project-scaffold`): створи `src/hello_world/` з `greet()`, `add()`, `main()`, `tests/__init__.py`, `pyproject.toml`, `requirements.txt`, онови `README.md`; перевір наявність файлів і синтаксис.

**Крок 3 — create-build.** Виконай `@prompts/create-build.prompt.md` (навичка `skills/build-and-test`): створи `tests/test_main.py` з `test_greet()` і `test_basic_addition()`, `requirements-dev.txt`, виконуваний `scripts/ci.sh` і `scripts/ci.bat`; запусти тестовий прогін скрипта під поточну ОС.

**Крок 4 — create-actions.** Виконай `@prompts/create-actions.prompt.md` (навичка `skills/github-actions`): створи `.github/workflows/ci.yml` з матрицею `[ubuntu-latest, windows-latest, macos-latest]`, що викликає лише `scripts/ci.sh` / `scripts/ci.bat`; валідуй YAML.

**Крок 5 — check.** Виконай `@prompts/check.prompt.md`: фінальна діагностика без змін проєкту — структура, YAML, запуск скрипта збірки, звіт `[OK]` / `[FAIL]`.

### Ідемпотентність

Повторний запуск `init` на вже налаштованому проєкті безпечний і не руйнує файли:

- `git init` не виконується, якщо репозиторій уже існує;
- файли, що збігаються з шаблонами, пропускаються; файли, що відрізняються, не перезаписуються без підтвердження користувача;
- `.gitignore`, `README.md`, `requirements-dev.txt` лише доповнюються відсутніми рядками чи розділами — без дублювання;
- `.venv` не створюється заново, якщо вже існує;
- `ci.yml` не змінюється, якщо відповідає вимогам.

Очікуваний результат повторного запуску — ті самі статуси `[OK]` для всіх етапів і порожня різниця в `git diff` для вже наявних файлів.

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
.venv/                      # артефакт, ігнорується Git
```

## Verification

Успіх оркестратора визначається результатом кроку 5 (`check`): загальний статус `RESULT: [OK]`, усі файли з Expected Files наявні, скрипт збірки завершився з кодом 0, тести `test_greet` і `test_basic_addition` пройшли.

Після успішного виконання всіх кроків виведи підсумковий звіт:

```text
=== init: summary ===

| Етап           | Статус | Артефакти                                                        |
|----------------|--------|------------------------------------------------------------------|
| git-init       | [OK]   | .git/, .gitignore                                                |
| create-project | [OK]   | src/hello_world/{__init__,main}.py, tests/__init__.py,           |
|                |        | pyproject.toml, requirements.txt, README.md                      |
| create-build   | [OK]   | tests/test_main.py, requirements-dev.txt,                        |
|                |        | scripts/ci.sh, scripts/ci.bat, .venv/                            |
| create-actions | [OK]   | .github/workflows/ci.yml                                         |
| check          | [OK]   | звіт діагностики: RESULT: [OK]                                   |

Створено / оновлено: <N> файлів, пропущено як актуальні: <M>
Тести: test_greet PASSED, test_basic_addition PASSED
Repository status: READY
```

Для кожного артефакту в звіті вказуй, чи його було створено, оновлено (доповнено) або пропущено як актуальний.

## Error Handling

Оркестратор працює за принципом **fail-fast**: на першій помилці будь-якого етапу він негайно зупиняється, наступні етапи не запускаються, а вже створені файли не видаляються й не відкочуються.

Помилкою вважається: відсутня передумова (файл, інструмент, prompt-файл чи навичка), ненульовий код повернення команди (`git`, `python -m venv`, `pip install`, `pytest`, `scripts/ci.sh` / `scripts/ci.bat`), невалідний YAML або `[FAIL]` у звіті `check`.

При зупинці виведи повідомлення у форматі:

```text
[FAIL] init зупинено на кроці <N/5>: <етап>
Причина: <що саме пішло не так: команда і код повернення або відсутній файл>
Деталі: <ключовий фрагмент виводу, напр. tests/test_main.py::test_basic_addition FAILED — AssertionError: assert 6 == 5>
Що зробити: <конкретна дія для виправлення>
Після виправлення: перезапустіть @prompts/<етап>.prompt.md або весь ланцюжок @prompts/init.prompt.md
Repository status: NOT READY
```

Приклади інструкцій користувачу за етапами:

- **git-init** — встановіть Git або підтвердіть роботу в наявному батьківському репозиторії.
- **create-project** — встановіть Python 3.10+ або вирішіть конфлікт з наявним файлом (підтвердіть перезапис чи точкову правку).
- **create-build** — виправте код або тест, що впав; перевірте мережу / проксі для `pip`; виконайте `chmod +x scripts/ci.sh` при `Permission denied`; встановіть `python3-venv` при `ensurepip is not available`.
- **create-actions** — виправте відступи YAML, додайте відсутній runner у матрицю, приберіть прямі виклики `pip` / `pytest` з `ci.yml`.
- **check** — виконайте рекомендації з `[FAIL]`-рядків звіту діагностики.

Оскільки всі етапи ідемпотентні, після виправлення причини безпечно перезапустити весь `init`: уже виконані етапи пройдуть зі статусом `[OK]`, не змінюючи файлів.
