---
name: github-actions
description: Створює workflow .github/workflows/ci.yml для автоматичного тестування Python-проєкту в GitHub Actions на матриці ubuntu-latest, windows-latest, macos-latest. Workflow викликає лише scripts/ci.sh або scripts/ci.bat. Використовується командою create-actions і оркестратором init.
---

# Skill: github-actions

## 1. Призначення

Навичка застосовується після `skills/build-and-test`: на етапі `create-actions` (`@prompts/create-actions.prompt.md`) і як четвертий крок оркестратора `init`. Вона створює workflow `.github/workflows/ci.yml`, який автоматично тестує код у GitHub Actions на матриці з трьох операційних систем. Workflow не містить власної логіки збірки: він лише готує runner і запускає ті самі скрипти, що й розробник локально, тому результат у CI збігається з локальним.

## 2. Вхідні дані (Inputs)

- **Скрипти збірки:** `scripts/ci.sh` (Linux/macOS) і `scripts/ci.bat` (Windows), створені навичкою `build-and-test` і успішно виконані локально (код повернення 0).
- **Гілки тригерів:** `push` і `pull_request` у гілки `develop`, `master`, `main`.
- **Версії Python:** `3.10` і `3.12` (мінімальна підтримувана та актуальна).

## 3. Очікувані результати (Outputs)

```text
.github/
└── workflows/
    └── ci.yml
```

> **Сувора вимога.** Workflow не повинен містити прямих викликів `pip`, `pytest` чи `python -m ...` для збірки й тестів. Дозволені лише кроки підготовки (`actions/checkout`, `actions/setup-python`) і запуск `scripts/ci.sh` (Linux/macOS) або `scripts/ci.bat` (Windows). Уся логіка встановлення залежностей і тестування живе в скриптах.

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [develop, master, main]
  pull_request:
    branches: [develop, master, main]

jobs:
  build:
    name: ${{ matrix.os }} / Python ${{ matrix.python-version }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ["3.10", "3.12"]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Build and test (Linux / macOS)
        if: runner.os != 'Windows'
        shell: bash
        run: bash scripts/ci.sh

      - name: Build and test (Windows)
        if: runner.os == 'Windows'
        shell: cmd
        run: scripts\ci.bat
```

Пояснення до структури. Тригери `push` і `pull_request` обмежено гілками `develop`, `master`, `main`. Матриця `os` містить рівно три runner, а `fail-fast: false` не дає падінню на одній ОС скасувати перевірку на інших. Вибір скрипта робиться через `if: runner.os`: на Linux і macOS — `bash scripts/ci.sh` з `shell: bash` (запуск через `bash` не залежить від біта виконання), на Windows — `scripts\ci.bat` з `shell: cmd`. Версії Python у лапках, щоб YAML не перетворив `3.10` на число `3.1`. Секрети й токени у workflow не використовуються.

## 4. Команди перевірки (Verification)

**Валідація синтаксису YAML.** Через Python (потрібен PyYAML) або `yamllint`:

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "[OK] YAML syntax"
yamllint -d "{extends: default, rules: {line-length: disable, truthy: disable}}" .github/workflows/ci.yml
```

На Windows замість `python3` використовується `python`. Правило `truthy` вимкнено, бо ключ `on:` — стандарт GitHub Actions.

**Перевірка структури кроків і матриці.** Скрипт перевіряє тригери, наявність усіх трьох runner, виклики `ci.sh` / `ci.bat` і відсутність прямих викликів `pip` / `pytest`:

```bash
python3 - <<'EOF'
import sys, yaml

wf = yaml.safe_load(open(".github/workflows/ci.yml"))
on = wf.get("on", wf.get(True))          # PyYAML читає ключ `on` як True
errors = []

for event in ("push", "pull_request"):
    branches = set((on.get(event) or {}).get("branches", []))
    if not {"develop", "master", "main"} <= branches:
        errors.append(f"{event}: потрібні гілки develop, master, main")

job = wf["jobs"]["build"]
oses = set(job["strategy"]["matrix"]["os"])
missing = {"ubuntu-latest", "windows-latest", "macos-latest"} - oses
if missing:
    errors.append(f"у матриці бракує runner: {sorted(missing)}")

runs = [s.get("run", "") for s in job["steps"]]
if not any("scripts/ci.sh" in r for r in runs):
    errors.append("немає кроку запуску scripts/ci.sh")
if not any("scripts\\ci.bat" in r for r in runs):
    errors.append("немає кроку запуску scripts\\ci.bat")
for r in runs:
    if any(word in r.split() for word in ("pip", "pytest")) or "-m pip" in r or "-m pytest" in r:
        errors.append(f"прямий виклик pip/pytest заборонено: {r!r}")

if errors:
    print("[FAIL]\n" + "\n".join(errors)); sys.exit(1)
print("[OK] Workflow structure")
EOF
```

Додатково — швидка текстова перевірка, що в workflow немає `pip` і `pytest`. Заперечення `!` перетворює «нічого не знайдено» на код 0, а будь-який збіг — на код 1 (провал):

```bash
! grep -nwE 'pip|pytest' .github/workflows/ci.yml
```

## 5. Типові сценарії помилок (Error Handling)

У всіх випадках агент працює за принципом fail-fast: зупиняє етап, не переходить до `check` і повідомляє користувачу етап, причину, рядок або ключ, де сталася помилка, і дію для виправлення. Повторний запуск навички ідемпотентний: якщо `ci.yml` уже існує і відповідає вимогам, агент його не змінює; якщо відрізняється, показує розбіжності і просить підтвердження перед правкою.

**Синтаксичні помилки форматування YAML.** Типові причини: табуляція замість пробілів, неоднаковий відступ, пропущена `:` або `-`, незакрита лапка. `yaml.safe_load` або `yamllint` повертає помилку з номером рядка, наприклад `mapping values are not allowed here (line 18, column 12)`. Агент показує цей рядок, виправляє відступи (2 пробіли на рівень) і повторює валідацію.

```text
[FAIL] Етап: create-actions
Причина: невалідний YAML у .github/workflows/ci.yml
Деталі: found character '\t' that cannot start any token (line 14, column 1)
Що зробити: замініть табуляцію на пробіли і перезапустіть @prompts/create-actions.prompt.md
```

**Відсутність одного з цільових runner у матриці.** Якщо в `matrix.os` бракує `ubuntu-latest`, `windows-latest` чи `macos-latest`, або там помилка в назві (`windows-lates`, `macos`), структурна перевірка завершується з `[FAIL]` і списком відсутніх runner. Агент додає відсутні значення і не прибирає жодну ОС, щоб «пройти» CI.

**Спроба запустити sh-скрипт на Windows безпосередньо.** Крок на кшталт `run: ./scripts/ci.sh` без умови `if` на Windows-runner падає (`'.' is not recognized as an internal or external command` у `cmd` або некоректні шляхи й CRLF у PowerShell). Агент розділяє запуск на два кроки з `if: runner.os != 'Windows'` → `bash scripts/ci.sh` і `if: runner.os == 'Windows'` → `scripts\ci.bat` (`shell: cmd`) і ніколи не викликає `ci.sh` на Windows.

**Прямий виклик `pip` / `pytest` у workflow.** Якщо структурна перевірка знаходить такі кроки, агент видаляє їх із `ci.yml` (після підтвердження) і переносить потрібну логіку в `scripts/ci.sh` та `scripts/ci.bat`, щоб зберегти єдине джерело правди для збірки.
