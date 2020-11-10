import UIKit

class ProgressViewController: UIViewController {
    private let text: String

    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var messageLabel: UILabel!

    init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = text
    }
}
