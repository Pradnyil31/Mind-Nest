# MindNest Architecture Overview

This project is being migrated towards a **feature-first** structure with clear layers.

## Structure

- `lib/features/<feature>/presentation` – Flutter widgets and screens (UI only).
- `lib/features/<feature>/application` – Controllers/state (Riverpod notifiers/providers).
- `lib/features/<feature>/domain` – Pure Dart models and business logic.
- `lib/features/<feature>/infrastructure` – Data access (Firebase/HTTP, repositories, services).

Shared cross-cutting code that is not specific to one feature (e.g. theme, core utilities) stays in existing top-level folders like `theme/`, `core/`, etc.

Over time, screens and logic from `lib/screens`, `lib/widgets`, `lib/services`, and `lib/providers` will be moved into the appropriate feature folders in **small, safe steps**, without changing behavior.

