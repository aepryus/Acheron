import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct WovenField {
    let name: String
    let isKids: Bool
    /// The type as written, when it was written: `loomSet` uses it to convert without asking at runtime.
    let type: String?
}

/// The scalar types a document can hold. Anything else — a Domain, a Packable, an array, a field
/// with no written type — goes through the general `loomConvert`, which works the type out as it runs.
let loomScalars: [String: String] = [
    "String": "loomString", "Int": "loomInt", "Double": "loomDouble", "Bool": "loomBool", "Date": "loomDate",
]

func wovenFields(of declaration: some DeclGroupSyntax) -> [WovenField] {
    var fields: [WovenField] = []
    for member in declaration.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        var kind: String? = nil
        for attribute in varDecl.attributes {
            guard let attr = attribute.as(AttributeSyntax.self) else { continue }
            let name = attr.attributeName.trimmedDescription
            if name == "Field" || name == "Child" { kind = name }
        }
        guard let kind else { continue }
        for binding in varDecl.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let type: String? = binding.typeAnnotation?.type.trimmedDescription
            fields.append(WovenField(name: pattern.identifier.text, isKids: kind == "Child", type: type))
        }
    }
    return fields
}

/// What `loomSet` assigns for one field. A written scalar type converts directly; everything else
/// keeps the general path.
func conversion(of f: WovenField) -> String {
    guard !f.isKids, let type = f.type else { return "loomConvert(value, current: \(f.name), parent: self)" }
    let optional: Bool = type.hasSuffix("?")
    let bare: String = optional ? String(type.dropLast()) : type
    guard let converter = loomScalars[bare] else { return "loomConvert(value, current: \(f.name), parent: self)" }
    return optional ? "\(converter)(value)" : "\(converter)(value) ?? \(f.name)"
}

public struct DomainMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let fields = wovenFields(of: declaration)
        let props = fields.filter { !$0.isKids }.map { $0.name }
        let kids = fields.filter { $0.isKids }.map { $0.name }

        let access: String
        if declaration.modifiers.contains(where: { $0.name.text == "open" || $0.name.text == "public" }) { access = "public " } else { access = "" }

        var decls: [DeclSyntax] = []

        // the lists never change, and `load` walks them for every document: work them out once
        if !props.isEmpty {
            let list = props.map { "\"\($0)\"" }.joined(separator: ", ")
            decls.append("override \(raw: access)var properties: [String] { super.properties + [\(raw: list)] }")
        }
        // children, as in Classic: an empty list is left out of the document rather than written as []
        if !kids.isEmpty {
            let list = kids.map { "\"\($0)\"" }.joined(separator: ", ")
            decls.append("override \(raw: access)var children: [String] { super.children + [\(raw: list)] }")
        }

        var getCases: [String] = []
        var setCases: [String] = []
        for f in fields {
            getCases.append("case \"\(f.name)\": return \(f.name)")
            setCases.append("case \"\(f.name)\": \(f.name) = \(conversion(of: f))")
        }
        if !fields.isEmpty {
            decls.append("""
                override \(raw: access)func loomGet(_ field: String) -> Any? {
                    switch field {
                    \(raw: getCases.joined(separator: "\n        "))
                    default: return super.loomGet(field)
                    }
                }
                """)
            decls.append("""
                override \(raw: access)func loomSet(_ field: String, _ value: Any?) {
                    switch field {
                    \(raw: setCases.joined(separator: "\n        "))
                    default: super.loomSet(field, value)
                    }
                }
                """)
        }
        return decls
    }
}

func storageDeclaration(for declaration: some DeclSyntaxProtocol) -> (name: String, storage: DeclSyntax)? {
    guard let varDecl = declaration.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          let typeAnnotation = binding.typeAnnotation else { return nil }
    let name = pattern.identifier.text
    let type = typeAnnotation.type.trimmedDescription
    if let initializer = binding.initializer {
        return (name, "private var _\(raw: name): \(raw: type) \(raw: initializer.trimmedDescription)")
    }
    return (name, "private var _\(raw: name): \(raw: type)")
}

struct WeaveError: Error, CustomStringConvertible {
    let description: String
}

/// A field's `didSet`, as written. Declared observers don't survive the macro's own accessors, so the
/// setter runs the body itself; `willSet` has no such home and is refused rather than dropped.
func observer(of declaration: some DeclSyntaxProtocol) throws -> CodeBlockItemListSyntax? {
    guard let binding = declaration.as(VariableDeclSyntax.self)?.bindings.first,
          case .accessors(let accessors)? = binding.accessorBlock?.accessors else { return nil }
    if accessors.contains(where: { $0.accessorSpecifier.tokenKind == .keyword(.willSet) }) {
        throw WeaveError(description: "a woven field can't carry willSet; use didSet")
    }
    return accessors.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.didSet) })?.body?.statements
}

/// Inside the observer the field is its storage, as in a real didSet: an assignment there doesn't
/// re-enter the setter.
final class StorageRewriter: SyntaxRewriter {
    let name: String
    init(name: String) { self.name = name }

    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        guard node.base?.trimmedDescription == "self", node.declName.baseName.text == name else { return super.visit(node) }
        return ExprSyntax(node.with(\.declName, node.declName.with(\.baseName, node.declName.baseName.with(\.tokenKind, .identifier("_\(name)")))))
    }
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        guard node.baseName.text == name, node.keyPathInParent != \MemberAccessExprSyntax.declName else { return super.visit(node) }
        return ExprSyntax(node.with(\.baseName, node.baseName.with(\.tokenKind, .identifier("_\(name)"))))
    }
}

func captureAccessors(name: String, via didSetCall: String, inPlace: Bool = false, observer: CodeBlockItemListSyntax? = nil) -> [AccessorDeclSyntax] {
    var accessors: [AccessorDeclSyntax] = [
        """
        @storageRestrictions(initializes: _\(raw: name))
        init(initialValue) { _\(raw: name) = initialValue }
        """,
        "get { _\(raw: name) }",
    ]
    if let observer {
        let body = StorageRewriter(name: name).rewrite(observer)
        accessors.append("""
            set {
                let oldValue = _\(raw: name)
                _\(raw: name) = newValue
                \(raw: body.trimmedDescription)
                \(raw: didSetCall)(oldValue, _\(raw: name))
            }
            """)
        // no _modify: an in-place change goes through the setter, so the observer sees it
        return accessors
    }
    accessors.append("""
        set {
            let oldValue = _\(raw: name)
            _\(raw: name) = newValue
            \(raw: didSetCall)(oldValue, newValue)
        }
        """)
    if inPlace {
        accessors.append("""
            _modify {
                yield &_\(raw: name)
                loomDidMutate()
            }
            """)
    }
    return accessors
}

public struct FieldMacro: AccessorMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        guard let (name, _) = storageDeclaration(for: declaration) else { return [] }
        return captureAccessors(name: name, via: "loomDidSet", inPlace: true, observer: try observer(of: declaration))
    }
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let (_, storage) = storageDeclaration(for: declaration) else { return [] }
        return [storage]
    }
}


public struct ChildMacro: AccessorMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        guard let (name, _) = storageDeclaration(for: declaration) else { return [] }
        return captureAccessors(name: name, via: "loomDidSetChild", observer: try observer(of: declaration))
    }
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let (_, storage) = storageDeclaration(for: declaration) else { return [] }
        return [storage]
    }
}

@main
struct AcheronMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [DomainMacro.self, FieldMacro.self, ChildMacro.self]
}
