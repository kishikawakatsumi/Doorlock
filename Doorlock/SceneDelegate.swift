import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard
            let url = URLContexts.first?.url,
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let APIKey = queryItems.first(where: { $0.name == "APIKey" })?.value,
            let deviceID = queryItems.first(where: { $0.name == "deviceID" })?.value else { return }

        let userDefaults = UserDefaults(suiteName: appGroupID)
        userDefaults?.set(APIKey, forKey: "APIKey")
        userDefaults?.set(deviceID, forKey: "deviceID")

        switch url.path.dropFirst() {
        case "lock":
            Device.lock(APIKey: APIKey, deviceID: deviceID)
        case "unlock":
            Device.unlock(APIKey: APIKey, deviceID: deviceID)
        default:
            break
        }
    }
}
