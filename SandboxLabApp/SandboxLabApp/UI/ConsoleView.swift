import SwiftUI
import UIKit

struct ConsoleView: View {
    @ObservedObject var store: ConsoleStore

    var body: some View {
        List {
            ForEach(store.lines) { line in
                Text(line.text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Console")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Copy Log") {
                    UIPasteboard.general.string = store.plainText
                }
                Button("Clear") {
                    store.clear()
                }
            }
        }
    }
}
