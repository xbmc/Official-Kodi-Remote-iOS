import SwiftUI
import SwiftData

struct ShareView: View {
    @State var urlFromShareViewSheet: String
    
    init(urlFromShareViewSeet: String) {
        self.urlFromShareViewSheet = urlFromShareViewSeet
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(urlFromShareViewSheet)
                Button {
                    Task {
                        await saveLink(sharedLink: urlFromShareViewSheet)
                    }
                    self.close()
                } label: {
                    Text("Save Link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 5))
            }
            .padding()
            .toolbar {
                Button("Cancel") {
                    self.close()
                }
            }
            .navigationTitle("Add new bookmark")
        }
    }
    
    func saveLink(sharedLink: String) async {
        // do something
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("Close"), object: nil)
    }
}

//#Preview {
//    ShareView()
//}
