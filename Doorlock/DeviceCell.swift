import UIKit

final class DeviceCell: UICollectionViewListCell {
    var nickname: String = "" {
        didSet { nicknameLabel.text = nickname }
    }
    var deviceID: String = "" {
        didSet { deviceIDLabel.text = deviceID }
    }
    var status: Status? {
        didSet {
            guard let status = status else {
                statusSpinner.isHidden = false
                statusSpinner.startAnimating()
                statusView.isHidden = true
                return
            }
            statusSpinner.isHidden = true
            statusView.isHidden = false

            lockStatusImage.image = status.locked ? UIImage(systemName: "lock.fill") : UIImage(systemName: "lock.open.fill")
            responsiveStatusImage.image = status.responsive ? UIImage(systemName: "bolt.fill") : UIImage(systemName: "bolt.slash.fill")
            responsiveStatusImage.image = status.responsive ? UIImage(systemName: "bolt.fill") : UIImage(systemName: "bolt.slash.fill")
            batteryStatusImage.image = status.battery > 25 ? UIImage(systemName: "battery.100") : status.battery > 0 ? UIImage(systemName: "battery.25") : UIImage(systemName: "battery.0")
            batteryStatusLabel.text = "\(status.battery)%"
        }
    }

    var onLockButtonTapped: () -> Void = {}
    var onUnlockButtonTapped: () -> Void = {}

    @IBOutlet private var nicknameLabel: UILabel!
    @IBOutlet private var deviceIDLabel: UILabel!
    @IBOutlet private var lockButton: UIButton!
    @IBOutlet private var unlockButton: UIButton!

    @IBOutlet private var statusView: UIStackView!
    @IBOutlet private var statusSpinner: UIActivityIndicatorView!

    @IBOutlet private var lockStatusImage: UIImageView!
    @IBOutlet private var responsiveStatusImage: UIImageView!
    @IBOutlet private var batteryStatusImage: UIImageView!
    @IBOutlet private var batteryStatusLabel: UILabel!

    override func awakeFromNib() {
        lockButton.layer.borderWidth = 1
        lockButton.layer.borderColor = UIColor.label.cgColor
        lockButton.layer.cornerRadius = lockButton.bounds.height / 2

        unlockButton.layer.borderWidth = 1
        unlockButton.layer.borderColor = UIColor.label.cgColor
        unlockButton.layer.cornerRadius = lockButton.bounds.height / 2

        lockButton.addAction(UIAction { [weak self] _ in self?.onLockButtonTapped() }, for: .touchUpInside)
        unlockButton.addAction(UIAction { [weak self] _ in self?.onUnlockButtonTapped() }, for: .touchUpInside)
    }
}

final class Button: UIButton {
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                tintColor = .tertiaryLabel
                layer.borderColor = UIColor.tertiaryLabel.cgColor
            } else {
                tintColor = .label
                layer.borderColor = UIColor.label.cgColor
            }
        }
    }
}
