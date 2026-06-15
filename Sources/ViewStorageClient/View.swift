import ViewStorage
import SwiftUI

enum Testing: Int, RawRepresentable, ViewStorable {
    case hello
    case hi
}

/// A test view for the @ViewStorage macro. To test, use the canvas preview.
struct TestView: View {
    @State var id: String = "hello"
    
    @ViewStorage("storableValue", path: \Self.id) var storableValue: String = "hi"
    @ViewStorage("storableArray", path: \Self.id) var storableArray: [Testing] = [.hello]
    @ViewStorage("storableSet2", path: \Self.id) var storableSet: Set<Testing> = [Testing.hello]

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
            Divider()
            Text("Array: \(storableArray.description)")
            Button("Add to array") {
                storableArray.append(.hello)
            }
            Button("Remove from array") {
                storableArray.removeLast()
            }

            Divider()
            Text("Set: \(storableSet.description)")
            Button("Toggle Hi in set") {
                if storableSet.contains(Testing.hi) {
                    storableSet.remove(Testing.hi)
                } else {
                    storableSet.insert(Testing.hi)
                }
            }
            Button("Toggle Hello in set") {
                if storableSet.contains(Testing.hello) {
                    storableSet.remove(Testing.hello)
                } else {
                    storableSet.insert(Testing.hello)
                }
            }
        }
    }
}

#Preview {
    TestView()
}
