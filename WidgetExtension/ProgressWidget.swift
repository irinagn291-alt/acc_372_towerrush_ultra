import SwiftUI
import WidgetKit

@main struct ProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetIdentity.kind, provider: ProgressProvider()) { entry in
            ProgressWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetIdentity.widgetName)
        .description(WidgetIdentity.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
