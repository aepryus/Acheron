# Loom

An object-document mapper. Model classes are the schema; an aggregate and its children
persist as one JSON document in SQLite; assignment is the API. No migration files, no context
objects, no query language beyond SQL.

The charter — why the design is what it is — is `Sources/Acheron/Loom/LOOM.md`.

## Installing

```swift
.package(url: "https://github.com/aepryus/Acheron.git", branch: "master")
```

That is the **classic** dialect: no macros, no dependencies, nothing to approve. The **Weave**
dialect trades `@objc dynamic` for macros; enable it with a trait:

```swift
.package(url: "https://github.com/aepryus/Acheron.git", branch: "master", traits: ["Weave"])
```

From an Xcode project, add it to the package reference:

```
traits = (Weave, );
```

Xcode asks once per machine to trust the macro (`Trust & Enable`; `-skipMacroValidation` in
CI). That prompt belongs to the trait — classic consumers never see it.

## Models

Classic:

```swift
class Gadget: Domain {
    @objc dynamic var label: String = ""
    override var properties: [String] { super.properties + ["label"] }
}
class Widget: Anchor {
    @objc dynamic var name: String = ""
    @objc dynamic var gadgets: [Gadget] = []
    override var properties: [String] { super.properties + ["name"] }
    override var children: [String] { ["gadgets"] }
}
```

Weave:

```swift
enum Rating: String, Packable { case unknown, good, great }

@Domain class Gadget: Domain {
    @Field var label: String = ""
}
@Domain class Widget: Anchor {
    @Field var name: String = ""
    @Field var rating: Rating = .unknown
    @Child var gadgets: [Gadget] = []
}
```

`Anchor` is the unit of persistence; `Domain` is a node inside one. Field types: `String`,
`Int`, `Double`, `Bool`, `Date`, optionals, `[String]`, enums and `Codable` structs (add
`Packable`), and custom types implementing `Packable`'s `init?(String)` / `pack()`.

## Boot

```swift
let basket = Basket(SQLitePersist("MyApp"))

Loom.start(basket: basket, namespaces: ["MyApp"])                    // classic
Loom.start(basket: basket, types: [Widget.self, Gadget.self])        // Weave

basket.associate(type: "widget", only: "name")
```

## Reading and writing

```swift
let widget: Widget = Loom.create()

Loom.transact { widget.name = "Falcon" }

let again: Widget  = Loom.selectBy(iden: widget.iden)!   // same instance
let byKey: Widget? = Loom.selectBy(only: "Falcon")
let all: [Widget]  = Loom.selectAll()
```

Mutating a persisted Anchor outside a transact crashes. Reads need no transact. A transact
commits every dirty anchor, not only what its closure touched.

Children, classic — append and wire:

```swift
Loom.transact {
    widget.gadgets.append(gadget)
    widget.add(gadget)
}
Loom.transact {
    widget.gadgets.removeAll { $0 === gadget }
    widget.remove(gadget)
}
```

Weave does the wiring itself:

```swift
Loom.transact { widget.gadgets.append(gadget) }
Loom.transact { widget.gadgets.removeAll() }
```

From async code, `await Loom.transact { }` (Weave).

## Queries

```swift
let found: [Widget] = Loom.select(where: "apiid", is: someID)
let one: Widget?    = Loom.selectOne(where: "apiid", is: someID)
```

Field names are code, never user input. Queries scan a type's documents, which is instant at
document-store scale. If a hot field bottlenecks:

```swift
basket.index(type: "widget", field: "flightNo")
```

An expression index over `json_extract`; the documents stay the truth.

## Free mode

A Domain graph needs no basket:

```swift
let attributes = gadget.unload()
let clone = Gadget(attributes: attributes); clone.load(attributes: attributes)
let copy = Loom.domain(attributes: attributes, replicate: true)   // fresh idens
```

## Eras

Classic is the default; Weave is opt-in. Documents are format-identical, so an app moves
either way without touching stored data — the port is mechanical (`@objc dynamic var` →
`@Field var`, drop the lists, register the types), and so is the revert.

`swift test` runs the classic suite; `swift test --traits Weave` runs the Weave one.

## Sync

`fork`/`vers`, `syncPacket()` and the `Memory` table are the client half of a replication
protocol whose server is a separate project. Dormant until wired up; harmless otherwise.
