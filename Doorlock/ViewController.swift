import UIKit
import Combine
import WidgetKit

class ViewController: UIViewController, UICollectionViewDelegate {
    private var cancellables: Set<AnyCancellable> = []

    @IBOutlet private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Device>!

    override func viewDidLoad() {
        super.viewDidLoad()

        let cellRegistration = UICollectionView.CellRegistration<DeviceCell, Device>(cellNib: UINib(nibName: "DeviceCell", bundle: nil)) { (cell, indexPath, item) in
            cell.nickname = item.nickname
            cell.deviceID = item.deviceID
            cell.status = item.status

            cell.onLockButtonTapped = {
                WidgetCenter.shared.getCurrentConfigurations {
                    if case .success(let widgetInfo) = $0 {
                        widgetInfo
                            .compactMap { $0.configuration as? ConfigurationIntent}
                            .compactMap { $0.APIKey }
                            .forEach {
                                Device.lock(APIKey: $0, deviceID: item.deviceID)
                            }
                    }
                }
            }
            cell.onUnlockButtonTapped = {
                WidgetCenter.shared.getCurrentConfigurations {
                    if case .success(let widgetInfo) = $0 {
                        widgetInfo
                            .compactMap { $0.configuration as? ConfigurationIntent}
                            .compactMap { $0.APIKey }
                            .forEach {
                                Device.unlock(APIKey: $0, deviceID: item.deviceID)
                            }
                    }
                }
            }
        }

        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.showsSeparators = true
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: listConfiguration)

        dataSource = UICollectionViewDiffableDataSource<Int, Device>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        let userDefaults = UserDefaults(suiteName: appGroupID)
        guard let APIKey = userDefaults?.string(forKey: "APIKey") else {
            print("No APIKey found. Configure widget.")
            return
        }

        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)

        guard let endpoint = URL(string: "https://api.candyhouse.co/public/sesames") else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue(APIKey, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) -> Void in
            defer { session.finishTasksAndInvalidate() }
            
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    alert.dismiss(animated: true)
                })
                self?.present(alert, animated: true)
                return
            }
            guard let data = data else { return }
            guard let devices = try? JSONDecoder().decode([Device].self, from: data) else {
                if let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                   let error = errorResponse["error"] {
                    let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        alert.dismiss(animated: true)
                    })
                    self?.present(alert, animated: true)
                }
                return
            }

            var snapshot = NSDiffableDataSourceSnapshot<Int, Device>()
            snapshot.appendSections([0])
            snapshot.appendItems(devices)
            self?.dataSource.apply(snapshot)

            devices.enumerated().forEach { (index, device) in
                guard let endpoint = URL(string: "https://api.candyhouse.co/public/sesame/\(device.deviceID)") else { return }
                var request = URLRequest(url: endpoint)
                request.httpMethod = "GET"
                request.addValue(APIKey, forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) -> Void in
                    guard
                        let data = data,
                        let status = try? JSONDecoder().decode(Status.self, from: data) else { return }

                    guard var snapshot = self?.dataSource.snapshot() else { return }
                    var item = snapshot.itemIdentifiers(inSection: 0)[index]
                    snapshot.deleteItems([item])
                    item.status = status
                    snapshot.appendItems([item])
                    self?.dataSource.apply(snapshot)
                })
                task.resume()
            }
        })
        task.resume()

        NotificationCenter.default.publisher(for: Notification.Name("DoorlockResponseReceivedNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let userInfo = $0.userInfo else { return }
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
            }
            .store(in: &cancellables)
    }
}
