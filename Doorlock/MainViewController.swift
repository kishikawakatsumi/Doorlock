import UIKit
import Combine
import WidgetKit

class MainViewController: UIViewController, UICollectionViewDelegate {
    private var cancellables: Set<AnyCancellable> = []

    @IBOutlet private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Status>!

    override func viewDidLoad() {
        super.viewDidLoad()

        let cellRegistration = UICollectionView.CellRegistration<DeviceCell, Status>(cellNib: UINib(nibName: "DeviceCell", bundle: nil)) { (cell, indexPath, item) in
            let userDefaults = UserDefaults(suiteName: appGroupID)
            cell.deviceID = userDefaults?.string(forKey: "deviceID") ?? "N/A"
            cell.batteryPercentage = item.batteryPercentage
            cell.status = item.CHSesame2Status

            cell.onLockButtonTapped = {
                WidgetCenter.shared.getCurrentConfigurations {
                    if case .success(let widgetInfo) = $0 {
                        widgetInfo.forEach {
                            guard let config = $0.configuration as? ConfigurationIntent else { return }
                            guard let APIKey = config.APIKey, let secretKey = config.secretKey, let deviceID = config.deviceID else { return }
                            Device.lock(APIKey: APIKey, secretKey: secretKey, deviceID: deviceID)
                        }
                    }
                }
            }
            cell.onUnlockButtonTapped = {
                WidgetCenter.shared.getCurrentConfigurations {
                    if case .success(let widgetInfo) = $0 {
                        widgetInfo.forEach {
                            guard let config = $0.configuration as? ConfigurationIntent else { return }
                            guard let APIKey = config.APIKey, let secretKey = config.secretKey, let deviceID = config.deviceID else { return }
                            Device.unlock(APIKey: APIKey, secretKey: secretKey, deviceID: deviceID)
                        }
                    }
                }
            }
        }

        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.showsSeparators = true
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: listConfiguration)

        dataSource = UICollectionViewDiffableDataSource<Int, Status>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        refreshStatus()

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

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.refreshStatus()
                }
            }
            .store(in: &cancellables)
    }

    private func refreshStatus() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        guard let APIKey = userDefaults?.string(forKey: "APIKey") else { return }
        guard let deviceID = userDefaults?.string(forKey: "deviceID") else { return }

        let session = URLSession.shared

        guard let endpoint = URL(string: "https://app.candyhouse.co/api/sesame2/\(deviceID)") else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addValue(APIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) -> Void in
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    alert.dismiss(animated: true)
                })
                self?.present(alert, animated: true)
                return
            }
            guard let data = data else { return }
            guard let status = try? JSONDecoder().decode(Status.self, from: data) else {
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

            var snapshot = NSDiffableDataSourceSnapshot<Int, Status>()
            snapshot.appendSections([0])
            snapshot.appendItems([status])
            self?.dataSource.apply(snapshot)
        })
        task.resume()
    }
}
