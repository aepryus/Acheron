import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct WovenField {
    let name: String
    let isKids: Bool
}

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
            fields.append(WovenField(name: pattern.identifier.text, isKids: kind == "Child"))
        }
    }
    return fields
}

public struct DomainMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let fields = wovenFields(of: declaration)
        let props = fields.map { $0.name }

        let access: String
        if declaration.modifiers.contains(where: { $0.name.text == "open" || $0.name.text == "public" }) { access = "public " } else { access = "" }

        var decls: [DeclSyntax] = []

        if !props.isEmpty {
            let list = props.map { "\"\($0)\"" }.joined(separator: ", ")
            decls.append("override \(raw: access)var properties: [String] { super.properties + [\(raw: list)] }")
        }

        var getCases: [String] = []
        var setCases: [String] = []
        for f in fields {
            getCases.append("case \"\(f.name)\": return \(f.name)")
            setCases.append("case \"\(f.name)\": \(f.name) = loomConvert(value, current: \(f.name), parent: self)")
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

func captureAccessors(name: String, via didSetCall: String, inPlace: Bool = false) -> [AccessorDeclSyntax] {
    var accessors: [AccessorDeclSyntax] = [
        """
        @storageRestrictions(initializes: _\(raw: name))
        init(initialValue) { _\(raw: name) = initialValue }
        """,
        "get { _\(raw: name) }",
        """
        set {
            let oldValue = _\(raw: name)
            _\(raw: name) = newValue
            \(raw: didSetCall)(oldValue, newValue)
        }
        """,
    ]
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
        return captureAccessors(name: name, via: "loomDidSet", inPlace: true)
    }
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let (_, storage) = storageDeclaration(for: declaration) else { return [] }
        return [storage]
    }
}


public struct ChildMacro: AccessorMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        guard let (name, _) = storageDeclaration(for: declaration) else { return [] }
        return captureAccessors(name: name, via: "loomDidSetChild")
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
