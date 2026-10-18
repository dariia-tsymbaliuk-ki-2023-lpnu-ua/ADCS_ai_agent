---
description: Створює Hello World-проєкт за skills/project-scaffold — src/hello_world (greet, add, main), tests/, pyproject.toml, requirements.txt, оновлює README.md і перевіряє файли та синтаксис.
---

# Команда: create-project

Ти — Build & Automation Engineer (див. `.cursor/rules/build-engineer.mdc`). Виконай інструкції навички `skills/project-scaffold/SKILL.md` і створи структуру Python-проєкту. Працюй лише з відносними шляхами, за принципами fail-fast та ідемпотентності.

## Prerequisites

- Виконано `@prompts/git-init.prompt.md`: існують `.git/` і `.gitignore`.
- Python 3.10+ доступний: `python3 --version` (Linux/macOS) або `python --version` / `py -3 --version` (Windows).
- Прочитано `skills/project-scaffold/SKILL.md` — шаблони файлів беруться звідти.

## Actions

1. Перевір версію Python. Якщо вона нижча за 3.10 або Python відсутній — зупинись (див. Error Handling).
2. Для кожного файлу з переліку Expected Files:
   - якщо файлу немає — створи його за шаблоном із навички;
   - якщо файл існує і збігається з шаблоном — пропусти;
   - якщо файл існує і відрізняється — не перезаписуй, а повідом про конфлікт і попроси підтвердження.
3. `src/hello_world/main.py` має містити функції `greet()` (повертає `"Hello, World!"`), `add(a, b)` (повертає `a + b`) і точку входу `main()` з `if __name__ == "__main__": main()`.
4. `pyproject.toml` має містити `requires-python = ">=3.10"` і секцію `[tool.pytest.ini_options]` з `testpaths = ["tests"]` та `pythonpath = ["src"]`.
5. Онови `README.md`: якщо файл існує — дописуй лише відсутні розділи з описом проєкту та командами запуску, не змінюючи наявний вміст (дані власника тощо); якщо не існує — створи за шаблоном.

## Expected Files

```text
src/hello_world/__init__.py
src/hello_world/main.py          # greet(), add(), main()
tests/__init__.py
pyproject.toml                   # метадані + [tool.pytest.ini_options]
requirements.txt                 # runtime-залежності
README.md                        # опис проєкту та команди запуску
```

Тести `tests/test_main.py` і `requirements-dev.txt` створюються на етапі `create-build`; якщо навичка `project-scaffold` уже створила їх, наступний етап їх не перезаписує.

## Verification

Linux / macOS:

```bash
for f in src/hello_world/__init__.py src/hello_world/main.py tests/__init__.py \
         pyproject.toml requirements.txt README.md; do
  test -f "$f" || { echo "[FAIL] Missing: $f"; exit 1; }
done
python3 -m py_compile src/hello_world/__init__.py src/hello_world/main.py
python3 -c "import sys; sys.version_info >= (3, 11) and __import__('tomllib').load(open('pyproject.toml', 'rb'))"
PYTHONPATH=src python3 -m hello_world.main      # очікується: Hello, World!
```

Windows (cmd):

```bat
for %%f in (src\hello_world\__init__.py src\hello_world\main.py tests\__init__.py pyproject.toml requirements.txt README.md) do (
  if not exist "%%f" (echo [FAIL] Missing: %%f & exit /b 1)
)
python -m py_compile src\hello_world\__init__.py src\hello_world\main.py || exit /b 1
python -c "import sys; sys.version_info >= (3, 11) and __import__('tomllib').load(open('pyproject.toml', 'rb'))" || exit /b 1
set PYTHONPATH=src
python -m hello_world.main || exit /b 1
```

## Error Handling

- **Python відсутній або версія < 3.10** — нічого не створюй; повідом: `[FAIL] Етап: create-project — Python 3.10+ не знайдено; встановіть Python і перезапустіть @prompts/create-project.prompt.md`.
- **Не виконано `git-init`** (немає `.git/` або `.gitignore`) — зупинись і запропонуй спершу запустити `@prompts/git-init.prompt.md`.
- **Конфлікт з наявними файлами** — не перезаписуй і не видаляй; покажи розбіжності та попроси підтвердження. Якщо бракує лише обов'язкових елементів (`greet()`, `add()`, `main()`), запропонуй точкову правку.
- **Помилка `py_compile` або запуску `hello_world.main`** — етап провалено; покажи файл, рядок і текст помилки інтерпретатора; не переходь до `create-build`.
