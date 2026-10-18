---
description: За skills/github-actions створює .github/workflows/ci.yml з матрицею ubuntu-latest, windows-latest, macos-latest, що викликає лише scripts/ci.sh / scripts/ci.bat, і валідує YAML.
---

# Команда: create-actions

Ти — Build & Automation Engineer (див. `.cursor/rules/build-engineer.mdc`). Виконай інструкції навички `skills/github-actions/SKILL.md` і створи workflow GitHub Actions. Працюй лише з відносними шляхами, за принципами fail-fast та ідемпотентності.

## Prerequisites

- Виконано `@prompts/create-build.prompt.md`: існують `scripts/ci.sh` і `scripts/ci.bat`, і локальний прогін завершився з кодом 0.
- Для валідації доступний PyYAML (`python3 -c "import yaml"`) або `yamllint`.
- Прочитано `skills/github-actions/SKILL.md` — шаблон workflow береться звідти.

## Actions

1. Створи `.github/workflows/ci.yml` за шаблоном навички:
   - тригери `push` і `pull_request` у гілки `develop`, `master`, `main`;
   - job `build` з `runs-on: ${{ matrix.os }}`, `strategy.fail-fast: false` і матрицею `os: [ubuntu-latest, windows-latest, macos-latest]` та `python-version: ["3.10", "3.12"]`;
   - кроки: `actions/checkout@v4`, `actions/setup-python@v5` з `with: python-version: ${{ matrix.python-version }}`, потім `bash scripts/ci.sh` з `if: runner.os != 'Windows'` (`shell: bash`) і `scripts\ci.bat` з `if: runner.os == 'Windows'` (`shell: cmd`).
2. **Сувора вимога:** у workflow немає прямих викликів `pip`, `pytest` чи `python -m ...` для збірки й тестів — лише запуск `scripts/ci.sh` або `scripts/ci.bat`. Секрети й токени не використовуй.
3. Якщо `ci.yml` уже існує і відповідає вимогам — не змінюй його. Якщо відрізняється — покажи розбіжності й попроси підтвердження перед правкою.
4. Відступи — 2 пробіли на рівень, без табуляцій; версії Python беруться в лапки.

## Expected Files

```text
.github/workflows/ci.yml
```

## Verification

```bash
if python3 -c "import yaml" 2>/dev/null; then
  python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "[OK] YAML syntax"
else
  echo "[WARN] PyYAML not installed, skipping YAML parsing"
fi
if command -v yamllint >/dev/null 2>&1; then
  yamllint -d "{extends: default, rules: {line-length: disable, truthy: disable}}" .github/workflows/ci.yml
else
  echo "[WARN] yamllint not installed, skipping"
fi
! grep -nwE 'pip|pytest' .github/workflows/ci.yml
```

Також виконай структурну перевірку з розділу Verification у `skills/github-actions/SKILL.md`: тригери містять `develop`, `master`, `main`; матриця містить усі три runner; є кроки запуску `scripts/ci.sh` і `scripts\ci.bat`. На Windows замість `python3` використовуй `python`.

## Error Handling

- **Немає `scripts/ci.sh` або `scripts/ci.bat`** — зупинись і запропонуй запустити `@prompts/create-build.prompt.md`.
- **Синтаксична помилка YAML** (табуляція, неправильний відступ, пропущена `:`) — покажи рядок і колонку з повідомлення парсера, виправ відступи й повтори валідацію.
- **Бракує runner у матриці** або помилка в назві (`windows-lates`, `macos`) — додай відсутні значення; не прибирай жодну ОС.
- **Спроба запустити `ci.sh` на Windows** (наприклад, `run: ./scripts/ci.sh` без умови) — розділи кроки за `runner.os`, як описано в Actions.
- **Знайдено прямий виклик `pip` / `pytest`** — після підтвердження прибери його з `ci.yml` і перенеси логіку в `scripts/ci.*`.

У всіх випадках етап вважається проваленим, і оркестратор не переходить до `check`.
