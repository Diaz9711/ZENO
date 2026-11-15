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
        let foto = entrada.foto
        Group {
            if familia == .systemMedium {
                HStack(spacing: 0) {
                    LuzDeLumi(foto: foto)
                        .frame(width: 150)
                    textos(foto, grande: true)
                        .padding(.trailing, 18)
                        .padding(.vertical, 20)
                }
            } else {
                ZStack(alignment: .bottomLeading) {
                    LuzDeLumi(foto: foto)
                        .frame(width: 120, height: 120)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, -6)
                    textos(foto, grande: false)
                        .padding(14)
                }
            }
        }
        .containerBackground(for: .widget) {
            CieloDelWidget(foto: foto, centro: familia == .systemMedium ? UnitPoint(x: 0.2, y: 0.5) : UnitPoint(x: 0.5, y: 0.32))
        }
    }

    @ViewBuilder
    private func textos(_ foto: FotoDeZeno, grande: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if !grande { Spacer(minLength: 0) }
            Text(foto.inicio != nil ? "En curso" : "Ahora")
                .font(.texto(10, "SemiBold"))
                .kerning(1.3)
                .textCase(.uppercase)
                .foregroundStyle(Tinta.oro)
            if let tarea = foto.tarea {
                // El texto es de la persona: se oculta si el iPhone está bloqueado.
                Text(verbatim: tarea)
                    .font(.titulo(grande ? 20 : 16))
                    .foregroundStyle(Tinta.marfil)
                    .lineLimit(grande ? 3 : 2)
                    .minimumScaleFactor(0.8)
                    .privacySensitive()
            } else {
                Text("Lumi sigue aquí")
                    .font(.titulo(grande ? 20 : 16))
                    .foregroundStyle(Tinta.marfil)
            }
            if let inicio = foto.inicio, let fin = foto.fin, fin > .now {
                Text(timerInterval: inicio...fin, countsDown: true)
                    .font(.texto(12, "Medium"))
                    .monospacedDigit()
                    .foregroundStyle(Tinta.marfilSecundario)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
