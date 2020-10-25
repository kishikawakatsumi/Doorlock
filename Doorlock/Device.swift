import Foundation

struct Device: Codable, Hashable {
    let deviceID: String
    let serial: String
    let nickname: String
    var status: Status?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case serial
        case nickname
    }

    static func lock(APIKey: String, deviceID: String) {
        doCommand(APIKey: APIKey, deviceID: deviceID, command: "lock")
    }

    static func unlock(APIKey: String, deviceID: String) {
        doCommand(APIKey: APIKey, deviceID: deviceID, command: "unlock")
    }

    static private func doCommand(APIKey: String, deviceID: String, command: String) {
        guard let endpoint = URL(string: "https://api.candyhouse.co/public/sesame/\(deviceID)") else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(APIKey, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String : Any] = [
            "command": command,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])


        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            var userInfo = [AnyHashable: Any]()
            if let data = data {
                userInfo["data"] = data
            }
            if let error = error {
                userInfo["error"] = error
            }
            if let response = response as? HTTPURLResponse {
                userInfo["response"] = response
            }
            NotificationCenter.default.post(name: NSNotification.Name("DoorlockResponseReceivedNotification"), object: nil, userInfo: userInfo)
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}
