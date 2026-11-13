import Foundation

enum WidgetIdentity {
    static let group = "group.com.towerrush.arcade"
    static let kind = "com.towerrush.arcade.progress"
    static let scheme = "towerrush"
    static let route = "play"
    static let displayName = "Tower Rush"
    static let emptyHint = "Build your first tower."
    static let widgetName = "Your skyline"
    static let widgetDescription = "Your highest climb and the tower waiting to continue."
    static let icon = "square.stack.3d.up.fill"
    static let theme = "tower"
    static let accent: [Double] = [0.99, 0.76, 0.29]
    static let background: [Double] = [0.03, 0.06, 0.14]
    static let serif = false
    static var url: URL { URL(string: "\(scheme)://widget/\(route)")! }
    static func accepts(_ url: URL) -> Bool { url.scheme == scheme && url.host == "widget" && url.path == "/" + route }
}
