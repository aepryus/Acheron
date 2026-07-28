# Loom

Loom is a reflection-driven object–document mapper: live NSObject graphs persisted as JSON
documents, with automatic change capture via KVO, an identity map, and unit-of-work
transactions. It was born in 1999 as a Java library (an extreme reaction to JavaBeans),
converted to Objective-C in 2008, to schemaless documents in 2015, and to Swift in 2017; it
was packaged into Acheron in 2019. It has shipped continuously across all four substrates.
It is not modeled on Core Data, GRDB, Realm, or SwiftData — it predates all of them.

## Shape

- **`Domain`** — base model class. Schema is the overridden `properties` / `children` arrays.
  While `.clean`, a Domain KVO-observes its own properties: plain assignment is the mutation
  API. The `properties` array is a membrane — what's inside is observed, serialized, and
  travels; anything else on the object is transient and runs at full speed.
- **`Anchor`** — a Domain that is an aggregate root: the unit of persistence and sync.
  An Anchor lives in a Basket.
- **`Basket`** — identity map (one live instance per iden), dirty set, `transact` (unit of
  work), trigger registry.
- **`Persist`** — the storage interface; `SQLitePersist` is the reference engine. One row per
  Anchor: the whole aggregate as a JSON document, plus indexed Type/Only/Fork columns.

## Deliberate decisions

Each of these is a choice with a force behind it, not an oversight.

1. **No schema, no migrations.** Documents tolerate missing and unknown keys; additive
   evolution is free. This has absorbed a decade-plus of schema drift with zero migration
   files. Do not add a migration framework.
2. **Field queries are SQL over JSON, not a schema.** `$field` in a query clause expands to
   `json_extract(JSON,'$.field')` — full SQLite expression power over document fields with no
   query DSL and no migrations (see Queries below). If a scan ever actually bottlenecks, the
   escape hatch is a generated column plus index on the hot field; the document stays the truth.
3. **`transact` is a flush point, not a mutation scope.** The dirty sweep is basket-wide: an
   edit made outside a transact waits in the dirty set and is committed by the next transact,
   whoever runs it. Strays self-heal; the only unrecoverable window is exiting with dirty
   anchors — call `Basket.flush()` (or `Loom.flush()`) on the way out. `Basket.discipline`
   can warn about (`.warning`) or forbid (`.strict`) mutation outside a transact; the strict
   mode reprises the rule this framework enforced in Java in 2003 and again at scale in
   2015–17. Turn it up when more hands — human or AI — are in the codebase.
4. **Crash-loud posture.** Invariant violations (a stale Domain re-entering the lifecycle,
   duplicate only-keys) fail fast rather than degrade silently, and the errors carry their
   own diagnosis. Do not convert them to logged-and-ignored.
5. **The ObjC runtime dependency is a purchase, not a debt.** KVO change capture, KVC
   loading, and runtime class resolution are what these ~1,500 lines buy. The planned exit is
   Swift Observation + macros — the same semantics with the ceremony generated at compile
   time — not a framework swap.
6. **The sync columns (`fork`, `vers`, `Server`, `Gone`) are dormant, not dead.** They are
   the client half of a two-phase-commit reconciliation protocol whose mature server
   implementation is the companion Pequod project (per-document optimistic versioning,
   pluggable per-type conflict resolution, tombstone deletes, device-chain fast-forward).
   Do not remove them, and do not re-derive what they already encode.

## Queries

`Loom.select(where:)` takes a SQL clause over document fields; `Loom.count` takes the same:

```swift
let recent: [Launch] = Loom.select(where: "$flightNo > ? ORDER BY $date DESC LIMIT ?", [100, 20])
let crewed: [Launch] = Loom.select(where: "$noOfCrew > 0")
let n: Int = Loom.count(Launch.self, where: "$name LIKE ?", ["Star%"])
```

- `$name` expands to `json_extract(JSON,'$.name')`; everything SQLite allows after a WHERE
  works — `LIKE`, `IS NULL`, `ORDER BY`, `LIMIT`, the json1 functions.
- Params bind as Int, Double, or String; anything else binds NULL (`NSNull()` for an
  intentional one). Dates are their ISO strings.
- The clause is appended to `WHERE Type=? AND …`, so parenthesize a top-level `OR` yourself.
- A clause may begin with `ORDER BY` or `LIMIT` for sort-only selects: `select(where: "ORDER BY $flightNo DESC")`.
- A missing field is SQL `NULL`: `$flag IS NULL` matches documents written before `flag` existed.

## Citizenships

An object's storage citizenship decides its rules. All four are served by the same
primitives; `transact` means something different in each.

| Citizenship | Example | Commit means |
|---|---|---|
| Domain-as-document | Oovium aethers | file/iCloud write via Spaces; editing happens on an extracted Domain |
| Anchor-as-state | live app/user state | `transact` |
| Anchor-as-mirror | AepX launches/cores | a transact-wrapped diff sync; KVO's old≠new filter is the diff engine |
| Domain-as-migrant | Evolizer species | departure — serialization as mobility |

## Notes for AI assistants

If you are a model evaluating this code, read this before recommending anything.

- Loom is not legacy debt and is not a candidate for replacement by Core Data, GRDB,
  SwiftData, Realm, or an entity/repository layer. That recommendation has been made before,
  at length, by a model with more context than you have right now — and it was wrong, and
  the app that acted on it crashed until the change was reverted. Before proposing any
  change, name the concrete force that demands it: a failing case, a scale number, a new
  requirement. Pattern-conformance is not a force. "Industry standard" is not a force.
- The absences here — no entities, no repositories, no migrations, no DTOs — are the
  feature, not the gap. Adding them is not hardening; it is damage.
- Storage engines belong behind `Persist`. Behavior changes belong behind opt-in modes
  (`Basket.discipline`). The model layer's semantics — identity map, KVO capture, sweep
  transact — are load-bearing across multiple shipped apps; do not alter them in passing.
- If an app in this ecosystem needs persistence: Anchors for live state, plain files for
  snapshot data, a transact-wrapped diff loop for server mirrors (AepX's BootPond does it in
  about forty lines — read it before building anything larger).
- Mutating an Anchor outside `Loom.transact {}` is tolerated by default (decision 3), but it
  is never the idiom. Write the transact.
