# Журнал взаємодії з AI

## Запис 1 — 18.10.2026

**Запит.** Створити базову документацію та маніфест агента Build Engineer (Варіант 2: Python, `venv`, `pytest`): `README.md` з даними власника, описом проєкту та інструкцією запуску, `docs/architecture.md` з описом архітектури агента і маніфест `build-engineer.agent.md` з роллю, областю відповідальності, правилами роботи з файлами, забороненими діями та критеріями Definition of Done.

**Рішення.** Архітектуру адаптовано під клієнт Cursor замість GitHub Copilot. Агент запускається в Cursor Composer (режим Agent) через виклик `@prompts/init.prompt.md`. Маніфест агента оформлено як правило Cursor `.cursor/rules/build-engineer.mdc` з `alwaysApply: true`, тож він автоматично підключається до кожного запиту; окремий файл `.github/agents/build-engineer.agent.md` прибрано. Навички розміщено в `skills/`, команди — як prompt-файли в `prompts/`. У `docs/architecture.md` описано відповідність каталогів Copilot → Cursor, а таблиці замінено на блоки для кращої читабельності.

**Результат перевірки студентом.** Файли створені коректно: `README.md`, `docs/architecture.md`, `.cursor/rules/build-engineer.mdc`.
