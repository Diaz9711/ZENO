import WidgetKit
import SwiftUI

/// Las piezas de ZENO fuera de la app: el widget de inicio y el anillo en vivo.
@main
struct PaqueteDeWidgets: WidgetBundle {
    var body: some Widget {
        WidgetDeLumi()
        AnilloEnVivoWidget()
    }
}

// MARK: - Widget de inicio: Lumi y la tarea de ahora

struct WidgetDeLumi: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lumi", provider: Proveedor()) { entrada in
            VistaDelWidget(entrada: entrada)
                .widgetURL(EnlaceZeno.hoy)
        }
        .configurationDisplayName("Lumi")
        .description("Tu estrella y la tarea de ahora.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct Entrada: TimelineEntry {
    var date: Date
    var foto: FotoDeZeno
}

struct Proveedor: TimelineProvider {
    func placeholder(in context: Context) -> Entrada { Entrada(date: .now, foto: FotoDeZeno()) }

    func getSnapshot(in context: Context, completion: @escaping (Entrada) -> Void) {
        completion(Entrada(date: .now, foto: FotoDeZeno.leer() ?? FotoDeZeno()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entrada>) -> Void) {
        var foto = FotoDeZeno.leer() ?? FotoDeZeno()
        // Una foto de hace más de 12 horas ya no habla de "ahora": solo queda la luz.
        if Date.now.timeIntervalSince(foto.guardadaEn) > 12 * 3600 {
            foto.tarea = nil
            foto.inicio = nil
            foto.fin = nil
        }
        // La app avisa cuando algo cambia; si no, se mira otra vez en una hora.
        completion(Timeline(entries: [Entrada(date: .now, foto: foto)],
                            policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct VistaDelWidget: View {
    let entrada: Entrada
    @Environment(\.widgetFamily) private var familia

    var body: some View {
        let mediano = familia == .systemMedium
        VistaDeWidget(foto: entrada.foto, mediano: mediano, estilo: .cielo,
                      retrato: RetratoGuardado.imagen(ancho: mediano),
                      retratoCuadrado: RetratoGuardado.imagen(ancho: false))
            .environment(\.locale, Locale(identifier: entrada.foto.idioma))
            .containerBackground(for: .widget) { Tinta.cielo }
    }
}
