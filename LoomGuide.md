# Loom — User Guide

Loom is an object-document mapper: your model classes *are* the schema, an aggregate and its
children persist as one JSON document in SQLite, and mutation is capture — assignment is the
API. There are no migration files, no context objects to thread, and no query language to
learn beyond SQL itself. The design has been in continuous production since 1999 (Java →
Objective-C → Swift); this guide covers the Swift package.

For the reasoning behind the design — why there are no migrations, why `transact` works the
way it does, why errors crash loud — read the charter: `Sources/Acheron/Loom/LOOM.md`.

## Installing

```swift
.package(url: "https://github.com/aepryus/Acheron.git", branch: "master")
```

Loom ships in two dialects (see **Eras** below). The default is **classic** — no macros, no
extra dependencies, no build dialogs. To opt into the modern macro dialect (**Weave**), enable
the trait:

```swift
.package(url: "https://github.com/aepryus/Acheron.git", branch: "master", traits: ["Weave"])
```

From an Xcode app project, add the trait to the package reference in the project file:

```
traits = (Weave, );
```

The first Weave build asks you once, per machine, to trust the macro (`Trust & Enable` in
Xcode; `-skipMacroValidation` in CI). That dialog is Apple's consent gate for all Swift
macros — it belongs to the trait you just enabled, and classic consumers never see it.

## Declaring models — Weave dialect

```swift
enum Rating: String, Packable { case unknown, good, great }

struct Spec: Codable, Packable {
    var thrust: Double = 0
    var name: String = ""
}

@Domain class Gadget: Domain {
    @Field var label: String = ""
}

@Domain class Widget: Anchor {
    @Field var name: String = ""
    @Field var flightNo: Int = 0
    @Field var when: Date = Date()
    @Field var note: String? = nil
    @Field var tags: [String] = []
    @Field var rating: Rating = .unknown
    @Field var spec: Spec = Spec()
    @Child var gadgets: [Gadget] = []
}
```

- `Anchor` is an aggregate root — the unit of persistence. `Domain` is a node inside one.
- `@Field` marks a persisted property. Every field needs an explicit type and a default.
- `@Child` marks owned children — a `[Domain]` array, a scalar, or an optional. Children
  serialize inside their parent's document and their edits dirty the anchor.

Field citizenships, all first-class: `String`, `Int`, `Double`, `Bool`, `Date`, optionals,
`[String]`, enums (`enum E: String, Packable` or `Int` — one added word), Codable structs
(`struct S: Codable, Packable` — packs as JSON), custom types (implement `Packable`'s
`init?(String)` / `pack()` yourself, as Oovium's math chains do), `[Packable]` arrays, and
Domain-typed values via `@Field` when you want serialization *without* ownership. Note:
declare an enum `Packable` via *either* its raw type *or* `Codable`, not both — the compiler
will make you choose.

## Boot

```swift
let basket = Basket(SQLitePersist("MyApp"))
Loom.start(basket: basket, types: [Widget.self, Gadget.self])

basket.associate(type: "widget", only: "name")     // optional: a natural-key index
basket.index(type: "widget", field: "flightNo")    // optional: see Queries
```

Every persistable type is registered explicitly — no runtime class lookup, no namespace
scanning, and a type that goes missing fails loudly with instructions instead of silently
dropping documents.

## Reading and writing

```swift
let widget: Widget = Loom.create()

Loom.transact {
    widget.name = "Falcon"
    widget.flightNo = 7
    widget.gadgets.append(Gadget())     // wires parent, fires onAdded, captures
}

let again: Widget  = Loom.selectBy(iden: widget.iden)!   // identity map: same instance
let byKey: Widget? = Loom.selectBy(only: "Falcon")       // via associate(type:only:)
let all: [Widget]  = Loom.selectAll()
```

Assignment is the API. Setting a field on a clean object marks its anchor dirty;
`Loom.transact { }` commits every dirty anchor in one SQLite transaction (from async
contexts: `await Loom.transact { }` — identical semantics, returns after the commit lands). `transact` is a
flush point, not a mutation scope — an edit made outside one is logged as a stray (see
**Discipline**) and swept into the next commit. Nested transacts join the outer commit.

Child collections are plain Swift arrays:

```swift
Loom.transact { widget.gadgets.removeAll() }        // children retire: onRemoved + delete
Loom.transact {                                     // moving a child between anchors:
    other.gadgets.append(gadget)                    //   append to the new parent first,
    widget.gadgets.removeAll { $0 === gadget }      //   then remove from the old
}
Loom.transact { widget.delete() }                   // deletes cascade through the aggregate
```

## Queries

Ad hoc queries are SQL with one convenience: `$field` expands to
`json_extract(JSON,'$.field')`.

```swift
let big: [Widget]  = Loom.select(where: "$flightNo > ?", [100])
let sorted: [Widget] = Loom.select(where: "ORDER BY $flightNo DESC")
let n = Loom.count(Widget.self, where: "$name LIKE ?", ["Star%"])
```

**The contract: clauses are code.** Bind *values* through `?` parameters, always. Never
build a clause or a field name from user input — the dialect trusts its author.

Queries scan the type's documents, which is instant at document-store scale (thousands of
rows). If a hot field ever actually bottlenecks:

```swift
basket.index(type: "widget", field: "flightNo")
```

— an expression index the dialect's generated SQL matches automatically. Existing queries
accelerate with no call-site changes; the document remains the truth.

## Events, triggers, discipline

Override lifecycle hooks on any Domain: `onCreate`, `onEdit`, `onDelete`, `onAdded`,
`onRemoved`, `onLoad`, `onSave`. Or observe from outside:

```swift
basket.addBlock({ widget in ... }, class: Widget.self, event: .edit)
```

(Convention note: `.added` triggers key on the *parent's* class; `.removed` on the child's.)

`basket.discipline` controls stray-mutation policy: `.warning` (default) logs each mutation
made outside a transact, `.strict` crashes on them, `.tolerant` stays quiet. Strays are
committed by the next transact regardless — staleness, not loss.

## Two modes

**Anchor mode** is everything above: baskets, identity map, transact.

**Free mode** needs no basket at all — Domain graphs as pure to/from-JSON citizens:

```swift
let attributes = gadget.unload()                     // [String: Any]
let json = gadget.toJSON()
let clone = Gadget(attributes: attributes); clone.load(attributes: attributes)
let copy = Loom.domain(attributes: attributes, replicate: true)   // fresh idens, whole tree
```

Parents wire, children merge by `iden` (live instances update in place — hydration never
replaces an object you're holding), and documents move between modes freely.

## Classic dialect

With the Weave trait off you get the same engine with the pre-macro declaration surface —
seventeen years of production behind it:

```swift
class Widget: Anchor {
    @objc dynamic var name: String = ""
    @objc dynamic var flightNo: Int = 0
    @objc dynamic var gadgets: [Gadget] = []
    override var properties: [String] { super.properties + ["name", "flightNo"] }
    override var children: [String] { ["gadgets"] }
}

Loom.start(basket: basket, namespaces: ["MyApp"])
widget.add(gadget)      // classic child wiring is explicit
```

Documents are format-identical across dialects — same keys, same values, same coercions
(JSON key order is not canonical, so don't content-hash raw documents): an app can port from
classic to Weave (or revert) without touching its stored data. The port is mechanical — `@objc dynamic var` →
`@Field var`, delete the lists, register the types.

## Eras and fallback

| Era | Platforms | Enabled by | Machinery |
|---|---|---|---|
| Classic | Apple (default) | nothing | ObjC runtime (KVO/KVC) |
| Weave | all | `traits: ["Weave"]` | Swift macros |
| Wrap | Linux (default) | nothing | property wrappers (stdlib) |

Each era carries its own test suite: `swift test` exercises classic; `swift test --traits
Weave` exercises the macro dialect (the larger suite). A bare `swift test` announces which
era it covered — a green run of one era is not a run of the other.

Every tier is machinery — Loom has never required hand-written persistence boilerplate and
never will. If macros ever break on a toolchain update, revert your port commit and ride
classic; the era is a build decision, never a data decision.

## Sync

`fork`/`vers` columns, `syncPacket()`, and the `Memory` table are the client half of a
client/server replication protocol (per-document optimistic versioning, conflict resolution,
tombstones). The server half is the companion Pequod project. Dormant until wired to a
server; harmless otherwise. Don't remove them.

## For AI assistants

Before proposing structural changes, read `Sources/Acheron/Loom/LOOM.md` — the deliberate
decisions section exists specifically so you don't re-derive a decade of trade-offs from a
cold read.
