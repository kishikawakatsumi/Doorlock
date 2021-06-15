import UIKit
import WidgetKit
import KeychainAccess

private let teamID = Bundle.main.infoDictionary!["AppIdentifierPrefix"] ?? ""
let accessGroup = "\(teamID)com.kishikawakatsumi.Doorlock"

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        WidgetCenter.shared.getCurrentConfigurations {
            if case .success(let widgetInfo) = $0 {
                widgetInfo.forEach {
                    guard let config = $0.configuration as? ConfigurationIntent else { return }
                    guard let APIKey = config.APIKey, let secretKey = config.secretKey, let deviceID = config.deviceID else { return }

                    let keychain = Keychain(service: "com.kishikawakatsumi.Doorlock", accessGroup: accessGroup)
                    keychain["APIKey"] = APIKey
                    keychain["secretKey"] = secretKey
                    keychain["deviceID"] = deviceID
                }
            }
        }

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
