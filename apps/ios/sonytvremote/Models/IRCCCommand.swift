import Foundation

/// Sony's standard remote codes are public protocol constants, not credentials.
enum IRCCCommand: String {
    case power = "AAAAAQAAAAEAAAAVAw=="
    case up = "AAAAAQAAAAEAAAB0Aw=="
    case down = "AAAAAQAAAAEAAAB1Aw=="
    case left = "AAAAAQAAAAEAAAA0Aw=="
    case right = "AAAAAQAAAAEAAAAzAw=="
    case confirm = "AAAAAQAAAAEAAABlAw=="
    case home = "AAAAAQAAAAEAAABgAw=="
    case back = "AAAAAgAAAJcAAAAjAw=="
    case volumeUp = "AAAAAQAAAAEAAAASAw=="
    case volumeDown = "AAAAAQAAAAEAAAATAw=="
    case mute = "AAAAAQAAAAEAAAAUAw=="
    case play = "AAAAAgAAAJcAAAAaAw=="
    case pause = "AAAAAgAAAJcAAAAZAw=="

    nonisolated var tvName: String {
        switch self {
        case .power: return "Power"
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .confirm: return "Confirm"
        case .home: return "Home"
        case .back: return "Return"
        case .volumeUp: return "VolumeUp"
        case .volumeDown: return "VolumeDown"
        case .mute: return "Mute"
        case .play: return "Play"
        case .pause: return "Pause"
        }
    }
}
