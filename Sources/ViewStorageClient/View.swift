import ViewStorage
import SwiftUI

struct TestView: View {
    @State var id: String = "hello"

    @ViewStorage("storableValue", path: \Self.id) var storableValue: String = "hi"

    var body: some View {
        VStack {
            Text(storableValue)
            TextField("Value for \(id)", text: $storableValue)
            Button("Switch id") {
                id = (id == "hello") ? "world" : "hello"
            }
        }
    }
}

#Preview {
    TestView()
}
