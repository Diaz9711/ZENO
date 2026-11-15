import WidgetKit
import SwiftUI

/// Las piezas de ZENO fuera de la app: el anillo en vivo y el widget de inicio.
@main
struct PaqueteDeWidgets: WidgetBundle {
    var body: some Widget {
        WidgetDeLumi()
        AnilloEnVivoWidget()
    }
}

struct WidgetDeLumi: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lumi", provider: Proveedor()) { _ in
            Text(verbatim: "ZENO").containerBackground(.blue, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Proveedor: TimelineProvider {
    struct Entrada: TimelineEntry { var date: Date }
    func placeholder(in context: Context) -> Entrada { Entrada(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entrada) -> Void) { completion(Entrada(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entrada>) -> Void) {
        completion(Timeline(entries: [Entrada(date: .now)], policy: .never))
    }
}
