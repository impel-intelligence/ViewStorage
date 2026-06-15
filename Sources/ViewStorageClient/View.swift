import ViewStorage
import SwiftUI

/// A test view for the @ViewStorage macro. To test, use the canvas preview.
struct TestView: View {
    @State var id: String = "hello"
    
    @ViewStorage("storableValue", path: \Self.id) var storableValue: String = "hi"
    @ViewStorage("storableArray", path: \Self.id) var storableArray: [String] = ["hello"]
    @ViewStorage("storableArray", path: \Self.id) var storableSet: Set<String> = ["hello"]

    var body: some View {
        VStack {
            Text(storableValue)
            TextField("Value for \(id)", text: $storableValue)
            Button("Switch id") {
                id = (id == "hello") ? "world" : "hello"
            }
            
            Button("Change Defaults") {
                UserDefaults.standard.set("override value", forKey: "storableValue_\(id)")
            }
        }
    }
}

#Preview {
    TestView()
}
