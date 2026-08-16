# Loom

An object–document mapper: live object graphs persisted as JSON documents, with automatic
change capture, an identity map, and unit-of-work transactions. Born in 1999 as a Java
library — a reaction to JavaBeans — converted to Objective-C in 2008, to schemaless documents
in 2015, to Swift in 2017, and packaged into Acheron in 2019. It predates Core Data, GRDB,
Realm and SwiftData, and is not modeled on any of them.

## Shape

- **`Domain`** — base model class. Its `properties` list is the schema and the membrane: what
  is inside is captured, serialized and travels; anything else on the object is transient.
- **`Anchor`** — a Domain that is an aggregate root: the unit of persistence and of sync.
- **`Basket`** — identity map, dirty set, `transact`, trigger registry.
- **`Persist`** — the storage interface. `SQLitePersist` is the reference engine: one row per
  Anchor holding the whole aggregate as a JSON document, plus Type/Only/Fork columns.

## Deliberate decisions

1. **No schema, no migrations.** Documents tolerate missing and unknown keys, so additive
   evolution is free. This has absorbed a decade of drift with zero migration files. Do not
   add a migration framework.

2. **Queries are SQL over JSON.** `$field` in a clause expands to
   `json_extract(JSON,'$.field')` — SQLite's full expression power over document fields, with
   no DSL. If a hot field ever bottlenecks, `basket.index(type:field:)` adds an expression
   index the generated SQL matches; existing queries accelerate untouched and the document
   stays the truth.

3. **`transact` is a flush point, not a mutation scope — and a stray is a crash.** The sweep
   is basket-wide: whatever is dirty when a transact runs is committed by it, whoever ran it.
   Mutating a persisted Anchor outside a transact fails immediately, in every build, as it
   did in Java in 2003 and at scale in 2015-17. There is no mode to turn this off; a switch
   is the first thing reached for when the rule is inconvenient. Write the transact.

4. **The write serializes the live object.** `unload()` runs inside the persist transaction,
   not before it, so a write always reflects what is currently true. Two writes of the same
   anchor can be redundant but never stale, and no snapshot can go out of date between the
   sweep and the disk. Do not introduce a snapshot buffer: it converts a redundant write into
   a wrong one, and then needs machinery to order what ordering never mattered to.

5. **Crash-loud.** Invariant violations — a stale Domain re-entering the lifecycle, a
   duplicate only-key, a mutation outside a transact — fail fast rather than degrade quietly.
   These are coding errors; they surface the first time the code runs. Do not convert them to
   logged-and-ignored.

6. **The sync columns (`fork`, `vers`, `Server`, `Gone`) are dormant, not dead.** They are the
   client half of a reconciliation protocol whose server implementation is the Pequod project:
   per-document optimistic versioning, per-type conflict resolution, tombstone deletes,
   device-chain fast-forward. `Basket.dehydrate` and `deleteByID` are the unfinished client
   half of deleted-tracking; `syncPacket` sends `deleted: []` until it is. Do not remove any
   of it and do not re-derive what it already encodes.

7. **`Loom` is sugar; `Basket` is the unit.** The static facade is a convenience over a Basket
   you can construct, inject and multiply. A Loom app owns one store for the process
   lifetime, and at that shape a context threaded through every controller is ceremony with no
   payoff. Need two stores? Hold two Baskets.

## Using Loom

**Anchored state.** Subclass `Anchor` for aggregate roots and `Domain` for their children.
Create with `Loom.create()`; a fresh anchor may be configured freely before its first
transact. Every mutation of a persisted anchor goes inside one:
`Loom.transact { rocket.name = "Aepryus I" }` — never mutate first and flush with an empty
`Loom.transact {}` after. Reads need no transact. Unique keys via
`basket.associate(type:only:)` then `Loom.selectBy(only:)`. Scalars go through
`Loom.set(key:value:)` — no transact, no dirty tracking, by design.

**Free Domains.** Subclass `Domain` and never touch a basket. Out with `unload().toJSON()`,
back with `load(attributes:)` or `Loom.domain(attributes:)`, deep-clone with
`replicate: true`. No dirty, no transact, no sweep; persistence is your file write.

**Never.** Copy a `Persist` implementation into an app — subclass or import it; a copy has no
compile-time tie to its origin and drifts until it breaks. Add entities, repositories, DTOs
or a migration framework on top of Loom.

## Citizenships

An object's storage citizenship decides its rules; `transact` means something different in
each.

| Citizenship | Example | Commit means |
|---|---|---|
| Domain-as-document | Oovium aethers | file/iCloud write via Spaces |
| Anchor-as-state | live app/user state | `transact` |
| Anchor-as-mirror | AepX launches/cores | a transact-wrapped diff sync |
| Domain-as-migrant | Evolizer species | departure — serialization as mobility |

## Eras

One dialect per build, selected by a trait; the documents are the same either way, so the era
is a build decision and never a data decision.

- **Classic** — the default. `@objc dynamic` fields plus `properties`/`children` lists;
  capture through KVO, loading through KVC, classes resolved by name at runtime. Seventeen
  years in production, no dependencies, nothing to approve.
- **Weave** — opt-in with `traits: ["Weave"]`. `@Domain`/`@Field`/`@Child` generate the same
  schema and accessors at compile time, and `Loom.register` replaces runtime class lookup,
  which is what removes the ObjC runtime dependency and makes Linux reachable. Costs a
  swift-syntax dependency and Xcode's one-time macro consent.

If the macros ever break on a toolchain update, an app reverts its port commit and rides
Classic; its data does not move.

## Notes for AI assistants

- The absences here — no entities, no repositories, no migrations, no DTOs — are the feature.
  Adding them is not hardening.
- Storage engines belong behind `Persist`. The model layer's semantics — identity map, change
  capture, sweep transact — are load-bearing across shipped apps; do not alter them in
  passing.
- If an app here needs persistence: Anchors for live state, plain files for snapshot data, a
  transact-wrapped diff loop for server mirrors — AepX's BootPond does it in about forty
  lines. Read it before building anything larger.
