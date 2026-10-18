---
description: Перевіряє стан Git, ідемпотентно створює або доповнює .gitignore для Python і виводить git status --short.
---

# Команда: git-init

Ти — Build & Automation Engineer (див. `.cursor/rules/build-engineer.mdc`). Виконай перший етап підготовки репозиторію. Працюй лише з відносними шляхами від кореня репозиторію, за принципами fail-fast та ідемпотентності.

## Prerequisites

- Команда `git` доступна: `git --version` завершується з кодом 0.
- Поточний каталог — корінь проєкту (робочий каталог, відкритий у Cursor).

## Actions

1. Перевір стан Git: `git rev-parse --is-inside-work-tree`.
   - Якщо репозиторій уже існує — не ініціалізуй його повторно, лише виведи поточну гілку (`git branch --show-current`).
   - Якщо репозиторію немає — виконай `git init`.
2. Створи `.gitignore`, якщо його немає. Якщо файл існує — дописуй лише ті правила, яких у ньому бракує, не змінюючи й не видаляючи наявних рядків. Обов'язкові правила:

   ```text
   .venv/
   __pycache__/
   .pytest_cache/
   *.pyc
   build/
   dist/
   ```

3. Виведи стан репозиторію: `git status --short`.

Не виконуй `git add`, `git commit`, `git push`, `git reset`, `git clean` та інші команди, що змінюють історію або видаляють файли.

## Expected Files

- `.git/` — репозиторій (створений або наявний).
- `.gitignore` — містить усі шість обов'язкових правил, кожне рівно один раз.

## Verification

Linux / macOS:

```bash
git rev-parse --is-inside-work-tree
for r in '.venv/' '__pycache__/' '.pytest_cache/' '*.pyc' 'build/' 'dist/'; do
  grep -qxF "$r" .gitignore || { echo "[FAIL] .gitignore: missing $r"; exit 1; }
done
git status --short
```

Windows (cmd):

```bat
git rev-parse --is-inside-work-tree || exit /b 1
for %%r in (.venv/ __pycache__/ .pytest_cache/ *.pyc build/ dist/) do (
  findstr /x /c:"%%r" .gitignore >nul || (echo [FAIL] .gitignore: missing %%r & exit /b 1)
)
git status --short
```

Повторний запуск команди не повинен змінювати `.gitignore` (рядки не дублюються).

## Error Handling

- **`git` не встановлено** — зупинись, нічого не створюй і повідом: `[FAIL] Етап: git-init — git не знайдено; встановіть Git і перезапустіть @prompts/git-init.prompt.md`.
- **Каталог є частиною іншого репозиторію** (`git rev-parse --show-toplevel` вказує на батьківський каталог) — зупинись і попроси користувача підтвердити, чи працювати в ньому.
- **`.gitignore` недоступний для запису** — зупинись і повідом шлях та помилку ОС; не перезаписуй файл іншим способом.
- **Конфлікт правил** (у `.gitignore` є заперечення на кшталт `!.venv/`) — не видаляй їх, повідом користувачу і попроси рішення.
