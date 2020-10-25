import Foundation

struct Status: Codable, Hashable {
    let locked: Bool
    let battery: Int
    let responsive: Bool

    var statusText: String {
        "\(locked ? "locked" : "unlocked")"
    }
}
