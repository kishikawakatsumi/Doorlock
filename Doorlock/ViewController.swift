import UIKit
import Combine

class ViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []
    @IBOutlet private var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.publisher(for: Notification.Name("DoorlockResponseReceiveldNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if let userInfo = $0.userInfo {
                    let text = self?.textView.text ?? ""
                    self?.textView.text = "\(text)\n\(userInfo["response"] ?? "")"
                }
            }
            .store(in: &cancellables)
    }
}
