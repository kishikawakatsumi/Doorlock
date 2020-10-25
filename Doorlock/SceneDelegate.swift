import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)

        guard
            let url = URLContexts.first?.url,
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let apiKey = queryItems.first(where: { $0.name == "apiKey" })?.value,
            let deviceId = queryItems.first(where: { $0.name == "deviceId" })?.value else { return }


        guard let endpoint = URL(string: "https://api.candyhouse.co/public/sesame/\(deviceId)") else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"

        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String : Any] = [
            "command": url.path.dropFirst()
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                NotificationCenter.default.post(name: NSNotification.Name("DoorlockResponseReceiveldNotification"), object: nil, userInfo: ["response": error.localizedDescription])
            }
            if let response = response as? HTTPURLResponse {
                NotificationCenter.default.post(name: NSNotification.Name("DoorlockResponseReceiveldNotification"), object: nil, userInfo: ["response": "\(response.statusCode)"])
            }
            if let data = data {
                NotificationCenter.default.post(name: NSNotification.Name("DoorlockResponseReceiveldNotification"), object: nil, userInfo: ["response": String(data: data, encoding: .utf8) ?? ""])
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}
