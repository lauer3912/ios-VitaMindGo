import WidgetKit
import SwiftUI

struct VitaPocketWidgetEntry: TimelineEntry {
    let date: Date
    let heartRate: Int?
    let steps: Int?
    let sleepHours: Double?
}

// Data structure matching PersistenceService.WidgetHealthData
struct WidgetData: Codable {
    let steps: Int
    let heartRate: Int
    let sleepHours: Double
    let waterGlasses: Int
    let lastUpdated: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> VitaPocketWidgetEntry {
        VitaPocketWidgetEntry(date: Date(), heartRate: 72, steps: 8500, sleepHours: 7.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (VitaPocketWidgetEntry) -> Void) {
        let entry = VitaPocketWidgetEntry(date: Date(), heartRate: 72, steps: 8500, sleepHours: 7.5)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VitaPocketWidgetEntry>) -> Void) {
        // Read from App Group shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.ggsheng.VitaMind")
        var heartRate: Int? = 72
        var steps: Int? = 8500
        var sleepHours: Double? = 7.5
        
        if let data = sharedDefaults?.data(forKey: "widget_health_data"),
           let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) {
            heartRate = widgetData.heartRate
            steps = widgetData.steps
            sleepHours = widgetData.sleepHours
        }
        
        let entry = VitaPocketWidgetEntry(date: Date(), heartRate: heartRate, steps: steps, sleepHours: sleepHours)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct VitaPocketWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: VitaPocketWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("VitaMindGo")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            Spacer()
            if let hr = entry.heartRate {
                VStack(alignment: .leading) {
                    Text("\(hr)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("--")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .widgetBackground()
    }
}

struct MediumWidgetView: View {
    var entry: VitaPocketWidgetEntry

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                if let hr = entry.heartRate {
                    Text("\(hr)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
                if let steps = entry.steps {
                    Text("\(steps)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("steps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                if let sleep = entry.sleepHours {
                    Text(String(format: "%.1f", sleep))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .widgetBackground()
    }
}

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(UIColor.systemBackground))
        }
    }
}

@main
struct VitaPocketWidget: Widget {
    let kind: String = "VitaPocketWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VitaPocketWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VitaMindGo Widget")
        .description("View your health metrics at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}