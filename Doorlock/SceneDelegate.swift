import UIKit
import KeychainAccess

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        if !connectionOptions.urlContexts.isEmpty {
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard
            let url = URLContexts.first?.url,
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let APIKey = queryItems.first(where: { $0.name == "APIKey" })?.value,
            let secretKey = queryItems.first(where: { $0.name == "secretKey" })?.value,
            let deviceID = queryItems.first(where: { $0.name == "deviceID" })?.value else { return }

        let keychain = Keychain(service: "com.kishikawakatsumi.Doorlock", accessGroup: accessGroup)
        keychain["APIKey"] = APIKey
        keychain["secretKey"] = secretKey
        keychain["deviceID"] = deviceID

        switch url.path.dropFirst() {
        case "lock":
            Device.lock(APIKey: APIKey, secretKey: secretKey, deviceID: deviceID)
        case "unlock":
            Device.unlock(APIKey: APIKey, secretKey: secretKey, deviceID: deviceID)
        default:
            break
        }
    }
}
