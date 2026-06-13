import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@ViewStorage("key", path: \Self.id)` — an `@AppStorage` look-alike whose
/// `UserDefaults` key is composed at runtime from a static prefix and the value
/// of another property on the enclosing view: `"<key>_<value at path>"`.
public struct ViewStorageMacro {

    /// Shared parsing of the attached declaration / attribute arguments.
    private struct Parsed {
        let propertyName: String
        let typeName: String
        let keyExpr: ExprSyntax        // the static prefix, e.g. "storableValue"
        let pathExpr: ExprSyntax       // the key path, e.g. \Self.id
        let defaultExpr: ExprSyntax    // the `= ...` initializer value
        var storeName: String { "\(propertyName)Store" }
    }

    private static func parse(
        _ node: AttributeSyntax,
        _ declaration: some DeclSyntaxProtocol
    ) -> Parsed? {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let typeName = binding.typeAnnotation?.type.trimmed.description else {
            return nil
        }

        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let keyExpr = arguments.first?.expression,
              let pathExpr = arguments.last?.expression else {
            return nil
        }

        guard let defaultExpr = binding.initializer?.value else {
            return nil
        }

        return Parsed(
            propertyName: propertyName,
            typeName: typeName,
            keyExpr: keyExpr,
            pathExpr: pathExpr,
            defaultExpr: defaultExpr
        )
    }

    /// Builds the runtime key expression: `<key> + "_" + "\(self[keyPath: <path>])"`.
    private static func keyExpr(_ parsed: Parsed) -> ExprSyntax {
        "\(parsed.keyExpr) + \"_\" + \"\\(self[keyPath: \(parsed.pathExpr)])\""
    }
}

// MARK: - Accessor expansion (turns the property into computed get / nonmutating set)

extension ViewStorageMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let parsed = parse(node, declaration) else { return [] }
        let store = parsed.storeName
        let key = keyExpr(parsed)

        let getter: AccessorDeclSyntax = """
        get {
            \(raw: store).value(forKey: \(key))
        }
        """

        let setter: AccessorDeclSyntax = """
        nonmutating set {
            \(raw: store).set(newValue, forKey: \(key))
        }
        """

        return [getter, setter]
    }
}

// MARK: - Peer expansion (the store + the $ projected binding)

extension ViewStorageMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let parsed = parse(node, declaration) else { return [] }
        let store = parsed.storeName
        let key = keyExpr(parsed)

        // Backing store — a DynamicProperty, so SwiftUI installs its @State.
        let storeDecl: DeclSyntax = """
        private var \(raw: store) = ViewStorageBox<\(raw: parsed.typeName)>(default: \(parsed.defaultExpr))
        """

        // Projected `$property` binding for controls like TextField.
        let binding: DeclSyntax = """
        var $\(raw: parsed.propertyName): SwiftUI.Binding<\(raw: parsed.typeName)> {
            SwiftUI.Binding(
                get: { \(raw: store).value(forKey: \(key)) },
                set: { newValue in \(raw: store).set(newValue, forKey: \(key)) }
            )
        }
        """

        return [storeDecl, binding]
    }
}

@main
struct ViewStoragePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ViewStorageMacro.self
    ]
}
