import SwiftUI
import AppIntents

/// Cómo se ve el anillo en la pantalla bloqueada. Vive en `Compartido` para poder
/// compararlo dentro de la app (galería `-galeriaAnillo YES`) con el mismo código del widget.
/// Nunca muestra el texto de la tarea (decisión de Diaz).
enum EstiloDeBloqueo: Int, CaseIterable, Identifiable {
    /// 1 · Una línea fina: anillo pequeño, tiempo en Fraunces y "Terminé" con borde de oro.
    case linea
    /// 2 · Barra de luz: frase en versalitas, tiempo a la derecha y una línea de oro que se consume.
    case barra
    /// 3 · Anillo en el botón: el tiempo grande y el anillo rodea el botón de terminar.
    case anilloEnBoton
    var id: Int { rawValue }
}

struct VistaDeBloqueo: View {
    let estado: AtributosDelAnillo.ContentState
    var estilo: EstiloDeBloqueo

    var body: some View {
        switch estilo {
        case .linea: linea
        case .barra: barra
        case .anilloEnBoton: anilloEnBoton
        }
    }

    // MARK: 1 · Línea fina

    private var linea: some View {
        HStack(spacing: 14) {
            ZStack {
                PuntoDeLuz(tamano: 10)
                AnilloQueSeConsume(estado: estado)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Versalitas("En curso")
                Text(timerInterval: estado.inicio...estado.fin, countsDown: true)
                    .font(.titulo(22))
                    .monospacedDigit()
                    .foregroundStyle(Tinta.marfil)
            }
            Spacer(minLength: 8)
            Button(intent: TerminarTareaIntent()) {
                Text("Terminé")
                    .font(.texto(12, "Medium"))
                    .kerning(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Tinta.oro)
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .overlay(Capsule().strokeBorder(Tinta.oro.opacity(0.7), lineWidth: 0.75))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: 2 · Barra de luz

    private var barra: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                PuntoDeLuz(tamano: 8)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                Versalitas("Lumi te acompaña")
                Spacer(minLength: 8)
                Text(timerInterval: estado.inicio...estado.fin, countsDown: true)
                    .font(.titulo(20))
                    .monospacedDigit()
                    .foregroundStyle(Tinta.marfil)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70, alignment: .trailing)
            }
            ProgressView(timerInterval: estado.inicio...estado.fin, countsDown: true) {
                EmptyView()
            } currentValueLabel: { EmptyView() }
                .progressViewStyle(.linear)
                .tint(Tinta.oro)
                .scaleEffect(x: 1, y: 0.35, anchor: .center)
            HStack {
                Spacer()
                Button(intent: TerminarTareaIntent()) {
                    HStack(spacing: 6) {
                        Text("Terminé")
                            .font(.texto(11, "SemiBold"))
                            .kerning(1.4)
                            .textCase(.uppercase)
                        Rectangle().frame(width: 14, height: 0.75)
                    }
                    .foregroundStyle(Tinta.oro)
                    .frame(height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: 3 · El anillo rodea el botón

    private var anilloEnBoton: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Versalitas("Lumi te acompaña")
                Text(timerInterval: estado.inicio...estado.fin, countsDown: true)
                    .font(.titulo(30))
                    .monospacedDigit()
                    .foregroundStyle(Tinta.marfil)
            }
            Spacer(minLength: 8)
            Button(intent: TerminarTareaIntent()) {
                ZStack {
                    AnilloQueSeConsume(estado: estado)
                    CheckFino()
                        .stroke(Tinta.oro, style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                        .frame(width: 14, height: 10)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Terminé"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

/// Etiqueta en versalitas doradas, como `EtiquetaLujo`.
struct Versalitas: View {
    let clave: LocalizedStringKey
    init(_ clave: LocalizedStringKey) { self.clave = clave }
    var body: some View {
        Text(clave)
            .font(.texto(10, "SemiBold"))
            .kerning(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Tinta.oro.opacity(0.9))
    }
}

/// La luz de Lumi en pequeño: un punto que se funde, sin borde.
struct PuntoDeLuz: View {
    var tamano: CGFloat
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.92, blue: 0.68), Color(red: 1, green: 0.88, blue: 0.55).opacity(0)],
                                 center: .center, startRadius: 0, endRadius: tamano))
            .frame(width: tamano * 2, height: tamano * 2)
    }
}

/// Check de trazo fino, dibujado a mano.
struct CheckFino: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.36, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        return p
    }
}

/// El anillo que se consume. En la pantalla bloqueada lo dibuja el sistema (se mueve solo);
/// en la galería de la app se dibuja quieto, igual de fino, para poder compararlo.
struct AnilloQueSeConsume: View {
    let estado: AtributosDelAnillo.ContentState
    var body: some View {
        #if WIDGET
        ProgressView(timerInterval: estado.inicio...estado.fin, countsDown: true) {
            EmptyView()
        } currentValueLabel: { EmptyView() }
            .progressViewStyle(.circular)
            .tint(Tinta.oro)
        #else
        let total = estado.fin.timeIntervalSince(estado.inicio)
        let queda = max(0, min(1, estado.fin.timeIntervalSinceNow / max(total, 1)))
        ZStack {
            Circle().stroke(Tinta.oro.opacity(0.18), lineWidth: 2.5)
            Circle().trim(from: 0, to: queda)
                .stroke(Tinta.oro, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(1.5)
        #endif
    }
}
