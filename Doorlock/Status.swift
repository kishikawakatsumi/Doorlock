import Foundation

struct Status: Codable, Hashable {
    let batteryPercentage: Int
    let batteryVoltage: Double
    let position: Int
    let CHSesame2Status: String
    let timestamp: Int
}
