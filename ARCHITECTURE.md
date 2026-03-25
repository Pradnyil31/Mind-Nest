# MindNest Architecture Overview

MindNest is moving toward a feature-first layered architecture with Riverpod-based dependency injection.

## Target layering

- `presentation`: Flutter screens/widgets (UI rendering only)
- `application`: controllers/use-cases/orchestration
- `domain`: entities/value objects/business rules
- `infrastructure`: Firebase/services/repositories

## Current DI policy

- UI must not instantiate services directly.
- UI must not perform direct Firestore collection queries.
- Shared Firebase instances (`Auth`, `Firestore`, `Functions`) are exposed via providers.
- Services receive dependencies through constructors/providers.

## Current status

- Home/Profile/Badges/Manage Routine and key widgets now consume provider-backed services only.
- Server-mediated AI chat is routed through Firebase Functions (`chatProxy`) by default.
- Firestore rules enforce owner access and immutable ownership fields for critical collections.
- Rules tests cover critical collections plus immutable `uid`/`createdAt` checks for user docs.

## Remaining migration direction

- Move large legacy screens from `lib/screens` into feature modules incrementally.
- Replace remaining singleton-like workflow classes with provider-injected orchestrators.
- Expand typed repository interfaces for high-read domains (analytics/reporting).
