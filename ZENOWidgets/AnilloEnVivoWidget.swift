import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

/// El anillo de tiempo fuera de la app: Isla Dinámica y pantalla bloqueada.
/// Sin alarma: al acabarse el tiempo el anillo queda vacío y en calma.
struct AnilloEnVivoWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AtributosDelAnillo.self) { contexto in
            // Pantalla bloqueada: nunca el texto de la tarea (decisión de Diaz).
            PantallaBloqueada(estado: contexto.state)
                .activityBackgroundTint(Tinta.cielo.opacity(0.92))
                .activitySystemActionForegroundColor(Tinta.marfil)
                .widgetURL(EnlaceZeno.hoy)
        } dynamicIsland: { contexto in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Anillo(estado: contexto.state, grosor: 3.5)
                        .frame(width: 46, height: 46)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TiempoRestante(estado: contexto.state, tamano: 26)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("En curso")
                            .font(.texto(11, "SemiBold"))
                            .kerning(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(Tinta.oro)
                        Text(verbatim: contexto.attributes.titulo)
                            .font(.titulo(17))
                            .foregroundStyle(Tinta.marfil)
                            .lineLimit(1)
                            .privacySensitive()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    BotonTermine()
                        .padding(.top, 6)
                }
            } compactLeading: {
                Anillo(estado: contexto.state, grosor: 2.5)
                    .frame(width: 22, height: 22)
            } compactTrailing: {
                TiempoRestante(estado: contexto.state, tamano: 14)
                    .frame(maxWidth: 46)
            } minimal: {
                Anillo(estado: contexto.state, grosor: 2.5)
                    .frame(width: 22, height: 22)
            }
            .widgetURL(EnlaceZeno.hoy)
            .keylineTint(Tinta.oro)
        }
    }
}

private struct PantallaBloqueada: View {
    let estado: AtributosDelAnillo.ContentState

    var body: some View {
        HStack(spacing: 16) {
            Anillo(estado: estado, grosor: 4)
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text("En curso")
                    .font(.texto(11, "SemiBold"))
                    .kerning(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Tinta.oro)
                Text("Lumi te acompaña")
                    .font(.titulo(19))
                    .foregroundStyle(Tinta.marfil)
                TiempoRestante(estado: estado, tamano: 15)
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
            BotonTermine()
                .frame(width: 112)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

/// El anillo que se consume, con la luz de Lumi en el centro.
private struct Anillo: View {
    let estado: AtributosDelAnillo.ContentState
    var grosor: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.9, blue: 0.62).opacity(0.85),
                                              Color(red: 1, green: 0.86, blue: 0.5).opacity(0)],
                                     center: .center, startRadius: 0, endRadius: 14))
                .padding(grosor * 2.2)
            ProgressView(timerInterval: estado.inicio...estado.fin, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(Tinta.oro)
        }
        .accessibilityLabel(Text("Tiempo de la tarea"))
    }
}

private struct TiempoRestante: View {
    let estado: AtributosDelAnillo.ContentState
    var tamano: CGFloat

    var body: some View {
        Text(timerInterval: estado.inicio...estado.fin, countsDown: true)
            .font(.texto(tamano, "Medium"))
            .monospacedDigit()
            .foregroundStyle(Tinta.marfil)
            .multilineTextAlignment(.trailing)
    }
}

/// "Terminé": la misma píldora dorada de ZENO. Solo tocar.
private struct BotonTermine: View {
    var body: some View {
        Button(intent: TerminarTareaIntent()) {
            Text("Terminé")
                .font(.texto(15, "SemiBold"))
                .foregroundStyle(Color(red: 0.12, green: 0.10, blue: 0.07))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Capsule().fill(LinearGradient(colors: [Tinta.oro, Tinta.oroHondo],
                                                          startPoint: .top, endPoint: .bottom)))
        }
        .buttonStyle(.plain)
    }
}
