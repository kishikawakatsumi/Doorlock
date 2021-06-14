import UIKit
import Combine
import WidgetKit

class MainViewController: UIViewController, UICollectionViewDelegate {
    private var cancellables: Set<AnyCancellable> = []

    @IBOutlet private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Device>!

    override func viewDidLoad() {
        super.viewDidLoad()

        let cellRegistration = UICollectionView.CellRegistration<DeviceCell, Device>(cellNib: UINib(nibName: "DeviceCell", bundle: nil)) { (cell, indexPath, item) in
            cell.nickname = item.nickname
            cell.deviceID = item.deviceID
            cell.status = item.status
        }

        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.showsSeparators = true
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: listConfiguration)

        dataSource = UICollectionViewDiffableDataSource<Int, Device>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        NotificationCenter.default.publisher(for: Notification.Name("DoorlockRequestStartedNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let userInfo = $0.userInfo as? [String: String], let command = userInfo["command"] else { return }

                let viewController = ProgressViewController(text: "\(command.capitalized)ing...")
                self?.present(viewController, animated: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notification.Name("DoorlockResponseReceivedNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (notification) in
                self?.dismiss(animated: true, completion: { [weak self] in
                    guard let userInfo = notification.userInfo else { return }

                    if let response = userInfo["response"] as? HTTPURLResponse {
                        if response.statusCode == 200 {
                            return
                        } else if let data = userInfo["data"] as? Data,
                                  let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                                  let error = errorResponse["error"] {
                            let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                alert.dismiss(animated: true)
                            })
                            self?.present(alert, animated: true)
                            return
                        }
                    } else if let error = userInfo["error"] as? Error {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            alert.dismiss(animated: true)
                        })
                        self?.present(alert, animated: true)
                        return
                    }

                    let alert = UIAlertController(title: "Error", message: "Unknown error occurred.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        alert.dismiss(animated: true)
                    })
                    self?.present(alert, animated: true)
                })
            }
            .store(in: &cancellables)
    }
}
