import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetContent {
        WidgetContent(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (WidgetContent) -> ()) {
        let entry = WidgetContent(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [WidgetContent(date: Date(), configuration: configuration)]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WidgetContent: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct DoorlockWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack {
            VStack {
                Image("key-solid")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding()
                Spacer()
            }
            HStack {
                Link(destination: Self.endpoint(APIKey: entry.configuration.APIKey ?? "", deviceID: entry.configuration.deviceID ?? "")) {
                    Label(widgetFamily == WidgetFamily.systemSmall ? "" : "Lock", systemImage: "lock.fill")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .font(.headline)
                        .padding(widgetFamily == WidgetFamily.systemSmall ? .trailing : .all, widgetFamily == WidgetFamily.systemSmall ? -8 : 16)
                        .padding(widgetFamily == WidgetFamily.systemSmall ? .all : .all, widgetFamily == WidgetFamily.systemSmall ? 16 : 0)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                        .offset(CGSize(width: 0, height: 6))
                }
                Link(destination: Self.endpoint(APIKey: entry.configuration.APIKey ?? "", deviceID: entry.configuration.deviceID ?? "")) {
                    Label(widgetFamily == WidgetFamily.systemSmall ? "" : "Unlock", systemImage: "lock.open.fill")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .font(.headline)
                        .padding(widgetFamily == WidgetFamily.systemSmall ? .trailing : .all, widgetFamily == WidgetFamily.systemSmall ? -8 : 16)
                        .padding(widgetFamily == WidgetFamily.systemSmall ? .all : .all, widgetFamily == WidgetFamily.systemSmall ? 16 : 0)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                        .offset(CGSize(width: 0, height: 6))
                }
            }
            .padding()
        }
    }

    private static func endpoint(APIKey: String, deviceID: String) -> URL {
        URL(string: "com.kishikawakatsumi.Doorlock:///unlock?APIKey=\(APIKey)&deviceID=\(deviceID)")!
    }
}

@main
struct DoorlockWidget: Widget {
    let kind: String = "DoorlockWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            DoorlockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Doorlock")
        .description("Configure your API key and device ID")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct DoorlockWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DoorlockWidgetEntryView(entry: WidgetContent(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            DoorlockWidgetEntryView(entry: WidgetContent(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            DoorlockWidgetEntryView(entry: WidgetContent(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
