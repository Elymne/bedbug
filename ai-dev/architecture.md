# Clean Architecture — Feature-based (Revised)

This project follows **Clean Architecture** with an **object-oriented** approach, organised around **features for business logic**, and a separate **application layer for UI and framework concerns**.

The architecture enforces a strict separation:

- **Features** → business logic only (domain + infrastructure)
- **Application** → UI and framework orchestration
- **Shared** → cross-cutting technical code (no business logic)

---

## High-level structure

The source code is split into three top-level folders:

```
features/
application/
shared/
```

---

## Features (Business layer)

Each feature is a **self-contained business module**.

It contains only business logic and its implementation, split into two layers:

```
features/
  feature_name/
    domain/
    infrastructure/
```

A feature **does not know anything about UI or frameworks**.

---

### Domain

The **core business logic layer**, completely independent from external systems.

#### Contains

- Entities
- Value objects
- Repository interfaces
- Gateway interfaces
- Use cases
- Domain extensions

#### Rules

- No external dependencies
- No framework imports
- No exceptions thrown
- Errors handled via `Either`

#### Structure

```
domain/
  entities/
  object_values/
  repositories/
  gateways/
  usecases/
  extensions/
  enums/ (only if global to the feature)
```

---

### Infrastructure

The **implementation layer** of domain contracts.

#### Contains

- Gateway implementations
- Datasources that are Repository implementations (API, DB, SDK)
- Models (DTOs, serialization)

#### Structure

```
infrastructure/
  datasources/
  models/
  gateways/
```

#### Rules

- Can use external libraries
- Can throw exceptions
- Implements domain interfaces only

---

## Application (UI & Framework layer)

The `application/` layer is completely separated from features.

It is responsible for:

- UI (pages, widgets)
- State management (notifiers, controllers)
- Orchestration of use cases
- Framework interaction (Flutter, etc.)

#### Structure

```
application/
  pages/
  widgets/
  controllers/
  notifiers/
```

#### Notes

- Pages can contain their own local widgets and state
- Application depends on **domain only**
- Never depends directly on infrastructure
- This is the **only layer aware of the framework**

---

## Shared (Technical layer)

`shared/` contains only **cross-cutting technical code**.

It must **never contain business logic**.

#### Typical contents

- Base classes and interfaces (`UseCase`, `Repository`, `Either`)
- Error handling (exceptions)
- Logger
- Helpers / utilities
- Technical extensions
- Configuration (SDKs, tools)
- Localization system

#### Example structure

```
shared/
  usecase/
  repository/
  exceptions/
  logger/
  helpers/
  extensions/
  config/
```

#### Rules

- No feature-specific logic
- No business rules
- No domain knowledge
- Structure emerges naturally (no forced layering)

---

## Dependency rules

Strict dependency direction:

```
application → domain → (interfaces) → infrastructure
shared → used by all
```

#### Constraints

- Application depends on **domain only**
- Domain depends on **nothing**
- Infrastructure depends on **domain + shared**
- Shared depends on **nothing**
- Features are isolated from each other

---

## Use cases

Each use case:

- Extends `UseCase<Success, Failure, Params>`
- Exposes `execute(params)`
- Returns `Either<Failure, Success>`

#### Rules

- No exceptions
- Failures are explicit and typed
- Use `NoParams` when no input is required

---

## Entities and Value Objects

### Entity

Base class for persisted objects:

- `id`
- `createdAt`
- `updatedAt`

#### Rules

- Immutable (`final`)
- `const` constructor
- Equality based on values

---

### ValueObject

Used for:

- Computed data
- Composite structures
- Concepts without identity

#### Rules

- Immutable (`final`)
- `const` constructor
- Equality based on values

---

## Enums

- Tied to a class → same file
- Shared in feature → `domain/enums/`

---

## Domain extensions

- Feature-specific → `feature/domain/extensions/`
- Cross-cutting → `shared/extensions/`

---

## Repository pattern

Each repository:

- Declared in domain
- Implemented in infrastructure
- Extends `Repository<Entity, Params>`

#### Features

- CRUD operations
- `getMany(params)` → returns `Page<Entity>`

#### Pagination strategies

- Cursor-based → `nextCursor`
- Offset-based → `nextOffset`

#### Rule

- Never simulate offset on cursor-based systems

---

## Core principles

- One file = one responsibility
- No mixing UI, business, and data access
- Business logic isolated in features
- UI decoupled from infrastructure
- Shared is purely technical
