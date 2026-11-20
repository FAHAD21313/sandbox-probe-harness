import SwiftUI
import UIKit

struct ConsoleView: View {
    @ObservedObject var store: ConsoleStore

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(store.lines) { line in
                    Text(line.text)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .id(line.id)
                }
            }
            .onChange(of: store.lines.count) { _, _ in
                if let last = store.lines.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
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
