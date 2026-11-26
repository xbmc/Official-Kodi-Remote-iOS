import UIKit
import SwiftUI

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first else {
            self.close()
            return
        }
        
        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
                if error != nil {
                    self.close()
                    return
                }
                
                // TODO: Add ability to choose between 'play' and 'queue'
                
                if let sharedUrl = url as? URL, let host = (url as? URL)?.host() {
                    if host.contains("youtube.com") || host.contains("youtu.be") {
                        debugPrint("Youtube URL Found:", sharedUrl)
                        self.close()
                        return
                    } else {
                        self.close()
                        return
                    }
                } else {
                    self.close()
                    return
                }
            }
        } else {
            close()
            return
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("Close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        NotificationCenter.default.post(name: NSNotification.Name("Close"), object: nil)
    }
}
