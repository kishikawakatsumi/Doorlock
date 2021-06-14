import Foundation
import CryptoSwift

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

    static func lock(APIKey: String, secretKey: String, deviceID: String) {
        doCommand(APIKey: APIKey, secretKey: secretKey, deviceID: deviceID, command: "lock")
    }

    static func unlock(APIKey: String, secretKey: String, deviceID: String) {
        doCommand(APIKey: APIKey, secretKey: secretKey, deviceID: deviceID, command: "unlock")
    }

    static private func doCommand(APIKey: String, secretKey: String, deviceID: String, command: String) {
        guard let endpoint = URL(string: "https://app.candyhouse.co/api/sesame2/\(deviceID)/cmd") else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(APIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let cmac = try? CMAC(key: Array<UInt8>(hex: secretKey)) else { return }

        let timestamp = Int32(Date().timeIntervalSince1970)
        let message = withUnsafeBytes(of: timestamp.littleEndian, Array.init).dropFirst()
        guard let digest = try? cmac.authenticate([UInt8](message)) else {
            return
        }
        let sign = digest.toHexString()

        let parameters: [String : Any] = [
            "cmd": command == "lock" ? 82 : 83, // 88/82/83 = toggle/lock/unlock
            "history": "(Web API)".data(using: .utf8)!.base64EncodedString(),
            "sign": sign
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("DoorlockRequestStartedNotification"), object: nil, userInfo: parameters)
        }

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            var userInfo = [AnyHashable: Any]()
            if let response = response as? HTTPURLResponse {
                userInfo["response"] = response
            }
            if let data = data {
                userInfo["data"] = data
                if let responseText = String(data: data, encoding: .utf8) {
                    print(responseText)
                }
            }
            if let error = error {
                userInfo["error"] = error
                print(error.localizedDescription)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DoorlockResponseReceivedNotification"), object: nil, userInfo: userInfo)
            }
        })
        task.resume()
    }
}
