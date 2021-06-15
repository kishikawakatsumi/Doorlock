import UIKit

final class DeviceCell: UICollectionViewListCell {
    var deviceID: String = "" {
        didSet { deviceIDLabel.text = deviceID }
    }
    var batteryPercentage: Int = 100 {
        didSet {
            batteryStatusImage.image = batteryPercentage > 25 ? UIImage(systemName: "battery.100") : batteryPercentage > 0 ? UIImage(systemName: "battery.25") : UIImage(systemName: "battery.0")
            batteryStatusLabel.text = "\(batteryPercentage)%"
        }
    }
    var status: String = "locked" {
        didSet {
            lockStatusImage.image = status == "locked" ? UIImage(systemName: "lock.fill") : UIImage(systemName: "lock.open.fill")
        }
    }

    var onLockButtonTapped: () -> Void = {}
    var onUnlockButtonTapped: () -> Void = {}

    @IBOutlet private var deviceIDLabel: UILabel!
    @IBOutlet private var lockButton: UIButton!
    @IBOutlet private var unlockButton: UIButton!

    @IBOutlet private var lockStatusImage: UIImageView!
    @IBOutlet private var batteryStatusImage: UIImageView!
    @IBOutlet private var batteryStatusLabel: UILabel!

    override func awakeFromNib() {
        if let font = deviceIDLabel.font {
            let features: [[UIFontDescriptor.FeatureKey: Int]] =
                [[.featureIdentifier: kNumberSpacingType, .typeIdentifier: kMonospacedNumbersSelector]]
            let fontDescriptor = font.fontDescriptor
            fontDescriptor.addingAttributes([.featureSettings: [features]])
            deviceIDLabel.font = UIFont(descriptor: fontDescriptor, size: 0)
        }
        if let font = batteryStatusLabel.font {
            let features: [[UIFontDescriptor.FeatureKey: Int]] =
                [[.featureIdentifier: kNumberSpacingType, .typeIdentifier: kMonospacedNumbersSelector]]
            let fontDescriptor = font.fontDescriptor
            fontDescriptor.addingAttributes([.featureSettings: [features]])
            batteryStatusLabel.font = UIFont(descriptor: fontDescriptor, size: 0)
        }

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
