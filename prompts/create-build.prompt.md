---
description: За skills/build-and-test створює tests/test_main.py (test_greet, test_basic_addition), requirements-dev.txt, виконувані scripts/ci.sh і scripts/ci.bat та запускає тестовий прогін збірки.
---

# Команда: create-build

Ти — Build & Automation Engineer (див. `.cursor/rules/build-engineer.mdc`). Виконай інструкції навички `skills/build-and-test/SKILL.md`: підготуй тести, залежності для розробки та кросплатформні скрипти збірки, а потім запусти збірку. Працюй лише з відносними шляхами, за принципами fail-fast та ідемпотентності.

## Prerequisites

- Виконано `@prompts/create-project.prompt.md`: існують `src/hello_world/main.py` (з `greet()`, `add()`, `main()`), `tests/__init__.py`, `pyproject.toml`, `requirements.txt`.
- Python 3.10+ з модулями `venv` і `pip`: `python3 -m venv --help` / `python -m venv --help`.
- Прочитано `skills/build-and-test/SKILL.md` — шаблони файлів беруться звідти.

## Actions

1. Створи `tests/test_main.py` з обов'язковими тестами `test_greet()` (`greet() == "Hello, World!"`) і `test_basic_addition()` (BasicAddition, `add(2, 3) == 5`). Якщо файл існує — не перезаписуй; перевір наявність обох тестів і за потреби запропонуй точкову правку.
2. Створи `requirements-dev.txt` з `-r requirements.txt` і `pytest>=7.0`. Якщо файл існує — лише дописуй відсутні рядки.
3. Згенеруй `scripts/ci.sh` (LF, `#!/usr/bin/env bash`, `set -euo pipefail`) і `scripts/ci.bat` (CRLF, `if errorlevel 1 exit /b 1` після кожної команди) за шаблонами навички. Обидва скрипти: створюють `.venv`, якщо його немає, оновлюють `pip`, встановлюють `requirements-dev.txt`, запускають `pytest` і `hello_world.main`.
4. Зроби `ci.sh` виконуваним:

   ```bash
   chmod +x scripts/ci.sh
   git update-index --add --chmod=+x scripts/ci.sh
   ```

5. Запусти тестовий прогін скрипта під поточну ОС: `./scripts/ci.sh` (Linux/macOS) або `scripts\ci.bat` (Windows).

## Expected Files

```text
tests/test_main.py               # test_greet(), test_basic_addition()
requirements-dev.txt             # -r requirements.txt, pytest
scripts/ci.sh                    # Linux / macOS, виконуваний
scripts/ci.bat                   # Windows
.venv/                           # створюється скриптом, ігнорується Git
```

## Verification

Linux / macOS:

```bash
test -x scripts/ci.sh || { echo "[FAIL] scripts/ci.sh is not executable"; exit 1; }
test -f scripts/ci.bat || { echo "[FAIL] Missing: scripts/ci.bat"; exit 1; }
grep -q 'def test_greet' tests/test_main.py && grep -q 'def test_basic_addition' tests/test_main.py \
  || { echo "[FAIL] Required tests missing"; exit 1; }
./scripts/ci.sh
echo "Exit code: $?"             # очікується 0
```

Windows (cmd):

```bat
if not exist scripts\ci.bat (echo [FAIL] Missing: scripts\ci.bat & exit /b 1)
if not exist scripts\ci.sh (echo [FAIL] Missing: scripts\ci.sh & exit /b 1)
findstr /c:"def test_greet" tests\test_main.py >nul || (echo [FAIL] test_greet missing & exit /b 1)
findstr /c:"def test_basic_addition" tests\test_main.py >nul || (echo [FAIL] test_basic_addition missing & exit /b 1)
scripts\ci.bat
echo Exit code: %errorlevel%
```

Успіх: код повернення 0, у виводі `pytest` тести `test_greet` і `test_basic_addition` мають статус `PASSED`, наприкінці — `[OK] Build and tests passed`. Повторний запуск теж завершується з кодом 0 і не створює `.venv` заново.

## Error Handling

- **Не виконано `create-project`** (немає `src/hello_world/main.py` або `pyproject.toml`) — зупинись і запропонуй запустити `@prompts/create-project.prompt.md`.
- **Падіння тестів (`AssertionError`)** — покажи назву тесту й рядок перевірки, запропонуй виправити `src/hello_world/main.py` або тест. Не видаляй тести й не додавай `skip` / `xfail`.
- **`Permission denied` для `ci.sh`** — виконай `chmod +x scripts/ci.sh` і повтори запуск; якщо причина в CRLF (`bad interpreter`), повідом і перезбережи файл з LF.
- **Збій `pip install`** (мережа, проксі, неіснуюча версія) — покажи повідомлення `pip`, перевір `requirements-dev.txt`; не встановлюй пакети глобально і не використовуй `sudo`.
- **`ensurepip is not available`** — повідом, що потрібно встановити `python3-venv`, і зупинись.

У всіх випадках етап вважається проваленим, і оркестратор не переходить до `create-actions`.
