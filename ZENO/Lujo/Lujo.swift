import SwiftUI
import Observation

// MARK: - Fichas de diseño (dirección LUXURY)
//
// Todo lo de los controles sale de aquí: colores, radios, sombras y movimiento.
// Regla: el oro champán es SOLO para botones, chips, interruptores, iconos y textos.
// La estrella y la nebulosa tienen sus propios colores y aquí no se tocan.

enum Lujo {
    // Color
    /// Oro champán: apagado y metálico. Se usa muy poco: acción principal, selección y estado activo.
    static let oro = Color(red: 0.851, green: 0.753, blue: 0.541)          // #D9C08A
    static let oroHondo = Color(red: 0.722, green: 0.592, blue: 0.353)     // #B8975A
    static let oroLuz = Color(red: 0.925, green: 0.867, blue: 0.722)       // reflejo del metal
    /// Marfil cálido para el texto (nunca blanco puro).
    static let marfil = Color(red: 0.949, green: 0.925, blue: 0.867)       // #F2ECDD
    static let marfilSecundario = Color(red: 0.949, green: 0.925, blue: 0.867).opacity(0.58)
    /// Rojizo apagado, solo para acciones que borran.
    static let rojizo = Color(red: 0.80, green: 0.53, blue: 0.47)
    /// Tinta oscura para el texto sobre oro.
    static let tinta = Color(red: 0.12, green: 0.10, blue: 0.08)
    /// Cristal esmerilado oscuro: apenas más claro que el fondo.
    static let cristal = Color(red: 0.10, green: 0.11, blue: 0.19).opacity(0.62)

    // Forma
    static let radioBoton: CGFloat = 16
    static let radioChip: CGFloat = 14
    static let radioTarjeta: CGFloat = 22
    static let radioHoja: CGFloat = 32
    static let altoBoton: CGFloat = 48
    static let altoMinimo: CGFloat = 44        // área táctil mínima
    static let margen: CGFloat = 28            // ~25 % más aire que antes
    static let espacio: CGFloat = 20

    // Movimiento: lento y delicado, sin rebote. cubic-bezier(0.22, 1, 0.36, 1).
    static func curva(_ duracion: Double = 0.55) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duracion)
    }
}

// MARK: - Letra

extension Font {
    /// Botones y etiquetas: Manrope ligera, pequeña; se escribe en mayúsculas con `.textCase(.uppercase)`.
    static func lujoEtiqueta(_ estilo: Font.TextStyle = .footnote, _ peso: Font.Weight = .regular) -> Font {
        .zenoTexto(estilo, peso)
    }
}

extension View {
    /// Mayúsculas pequeñas y espaciadas (≈0,08 em), como un grabado.
    func versalitas(_ espaciado: CGFloat = 1.4) -> some View {
        textCase(.uppercase).tracking(espaciado)
    }
}

// MARK: - Canto pulido y superficies

/// Borde de 0,75 pt con un reflejo de luz arriba que se apaga abajo, como el canto de una pieza pulida.
struct CantoPulido: ViewModifier {
    var radio: CGFloat
    var intensidad: Double = 1
    var oro = false

    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: radio, style: .continuous)
                .strokeBorder(LinearGradient(
                    colors: oro
                        ? [Lujo.oroLuz.opacity(0.9 * intensidad), Lujo.oro.opacity(0.55 * intensidad), Lujo.oroHondo.opacity(0.35 * intensidad)]
                        : [Lujo.marfil.opacity(0.22 * intensidad), Lujo.marfil.opacity(0.06 * intensidad), Lujo.marfil.opacity(0.02 * intensidad)],
                    startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
                .allowsHitTesting(false)
        }
    }
}

extension View {
    func cantoPulido(radio: CGFloat, intensidad: Double = 1, oro: Bool = false) -> some View {
        modifier(CantoPulido(radio: radio, intensidad: intensidad, oro: oro))
    }

    /// Tarjeta de lujo: cristal oscuro sutil, esquinas de 22 pt, reflejo fino arriba y sombra larga y suave.
    func tarjetaLujo(radio: CGFloat = Lujo.radioTarjeta) -> some View {
        background {
            RoundedRectangle(cornerRadius: radio, style: .continuous)
                .fill(Lujo.cristal)
                .shadow(color: .black.opacity(0.28), radius: 30, y: 18)
        }
        .cantoPulido(radio: radio)
    }
}

/// Un separador casi invisible dentro de una tarjeta.
struct SeparadorLujo: View {
    var body: some View {
        Rectangle().fill(Lujo.marfil.opacity(0.07)).frame(height: 0.5)
    }
}

// MARK: - Iconos finos (una sola familia, trazo de 1,1 pt)

enum IconoLujo { case calendario, reloj, papelera, campana, cerrar, mas, atras, check }

struct IconoFino: View {
    let icono: IconoLujo
    var color: Color = Lujo.marfil
    var tamano: CGFloat = 18
    var trazo: CGFloat = 1.1

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            var camino = Path()
            switch icono {
            case .calendario:
                camino.addRoundedRect(in: CGRect(x: 0.12 * s, y: 0.2 * s, width: 0.76 * s, height: 0.68 * s),
                                      cornerSize: CGSize(width: 0.12 * s, height: 0.12 * s))
                camino.move(to: p(0.12, 0.40)); camino.addLine(to: p(0.88, 0.40))
                camino.move(to: p(0.34, 0.10)); camino.addLine(to: p(0.34, 0.28))
                camino.move(to: p(0.66, 0.10)); camino.addLine(to: p(0.66, 0.28))
            case .reloj:
                camino.addEllipse(in: CGRect(x: 0.12 * s, y: 0.12 * s, width: 0.76 * s, height: 0.76 * s))
                camino.move(to: p(0.5, 0.28)); camino.addLine(to: p(0.5, 0.5)); camino.addLine(to: p(0.66, 0.6))
            case .papelera:
                camino.move(to: p(0.16, 0.26)); camino.addLine(to: p(0.84, 0.26))
                camino.move(to: p(0.38, 0.26)); camino.addLine(to: p(0.40, 0.14)); camino.addLine(to: p(0.60, 0.14)); camino.addLine(to: p(0.62, 0.26))
                camino.move(to: p(0.24, 0.26)); camino.addLine(to: p(0.30, 0.88)); camino.addLine(to: p(0.70, 0.88)); camino.addLine(to: p(0.76, 0.26))
                camino.move(to: p(0.44, 0.42)); camino.addLine(to: p(0.45, 0.74))
                camino.move(to: p(0.56, 0.42)); camino.addLine(to: p(0.55, 0.74))
            case .campana:
                camino.move(to: p(0.22, 0.72))
                camino.addCurve(to: p(0.5, 0.16), control1: p(0.30, 0.60), control2: p(0.24, 0.16))
                camino.addCurve(to: p(0.78, 0.72), control1: p(0.76, 0.16), control2: p(0.70, 0.60))
                camino.closeSubpath()
                camino.move(to: p(0.42, 0.84)); camino.addLine(to: p(0.58, 0.84))
            case .cerrar:
                camino.move(to: p(0.24, 0.24)); camino.addLine(to: p(0.76, 0.76))
                camino.move(to: p(0.76, 0.24)); camino.addLine(to: p(0.24, 0.76))
            case .mas:
                camino.move(to: p(0.5, 0.18)); camino.addLine(to: p(0.5, 0.82))
                camino.move(to: p(0.18, 0.5)); camino.addLine(to: p(0.82, 0.5))
            case .atras:
                camino.move(to: p(0.62, 0.2)); camino.addLine(to: p(0.32, 0.5)); camino.addLine(to: p(0.62, 0.8))
            case .check:
                camino.move(to: p(0.2, 0.52)); camino.addLine(to: p(0.42, 0.72)); camino.addLine(to: p(0.8, 0.3))
            }
            ctx.stroke(camino, with: .color(color), style: StrokeStyle(lineWidth: trazo, lineCap: .round, lineJoin: .round))
        }
        .frame(width: tamano, height: tamano)
        .accessibilityHidden(true)
    }
}

// MARK: - Botones (tres niveles)

/// Al tocar: baja a 0,97 sin rebote. El primario además deja pasar un reflejo, una vez.
struct EstiloLujo: ButtonStyle {
    var conReflejo = false
    func makeBody(configuration: Configuration) -> some View {
        CuerpoLujo(configuration: configuration, conReflejo: conReflejo)
    }

    private struct CuerpoLujo: View {
        let configuration: Configuration
        let conReflejo: Bool
        @State private var reflejo: CGFloat = -1
        @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

        var body: some View {
            configuration.label
                .overlay {
                    if conReflejo && !reducirMovimiento {
                        GeometryReader { geo in
                            LinearGradient(colors: [.clear, .white.opacity(0.38), .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: geo.size.width * 0.45)
                                .offset(x: reflejo * geo.size.width)
                                .blendMode(.softLight)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous))
                        .allowsHitTesting(false)
                    }
                }
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(Lujo.curva(0.35), value: configuration.isPressed)
                .onChange(of: configuration.isPressed) { _, presionado in
                    guard presionado, conReflejo, !reducirMovimiento else { return }
                    reflejo = -0.5
                    withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.1)) { reflejo = 1.1 }
                }
        }
    }
}

/// Primario: oro champán cepillado, línea de luz arriba y texto oscuro en mayúsculas espaciadas.
struct BotonPrimarioLujo: View {
    let titulo: LocalizedStringKey
    var ancho: CGFloat? = nil
    let accion: () -> Void
    @State private var toques = 0

    init(_ titulo: LocalizedStringKey, ancho: CGFloat? = nil, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.ancho = ancho
        self.accion = accion
    }

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            EtiquetaPrimaria(titulo: titulo, ancho: ancho)
        }
        .buttonStyle(EstiloLujo(conReflejo: true))
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: toques)
    }
}

private struct EtiquetaPrimaria: View {
    let titulo: LocalizedStringKey
    let ancho: CGFloat?
    @Environment(\.isEnabled) private var activo

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
        Text(titulo)
            .font(.lujoEtiqueta(.footnote, .semibold))
            .versalitas(1.8)
            .foregroundStyle(Lujo.tinta)
            .frame(maxWidth: ancho == nil ? .infinity : nil)
            .frame(width: ancho, height: Lujo.altoBoton)
            .padding(.horizontal, 22)
            .background {
                ZStack {
                    forma.fill(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo],
                                              startPoint: .top, endPoint: .bottom))
                    // Cepillado: líneas finísimas horizontales, como metal satinado.
                    Canvas { ctx, size in
                        var y: CGFloat = 1
                        while y < size.height {
                            var l = Path()
                            l.move(to: CGPoint(x: 0, y: y))
                            l.addLine(to: CGPoint(x: size.width, y: y))
                            ctx.stroke(l, with: .color(.white.opacity(y.truncatingRemainder(dividingBy: 3) < 1 ? 0.06 : 0.025)),
                                       lineWidth: 0.5)
                            y += 1.5
                        }
                    }
                    .clipShape(forma)
                }
                .shadow(color: Lujo.oroHondo.opacity(0.22), radius: 18, y: 10)
            }
            // La línea de luz del borde superior.
            .overlay(alignment: .top) {
                forma.strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.0)],
                                                  startPoint: .top, endPoint: .center), lineWidth: 0.75)
            }
            .opacity(activo ? 1 : 0.4)
            .animation(Lujo.curva(), value: activo)
            .contentShape(forma)
    }
}

/// Secundario: casi transparente, solo un borde fino y el texto en marfil. No compite con el primario.
struct BotonSecundarioLujo: View {
    let titulo: LocalizedStringKey
    var ancho: CGFloat? = nil
    let accion: () -> Void
    @State private var toques = 0

    init(_ titulo: LocalizedStringKey, ancho: CGFloat? = nil, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.ancho = ancho
        self.accion = accion
    }

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            Text(titulo)
                .font(.lujoEtiqueta(.footnote, .medium))
                .versalitas(1.8)
                .foregroundStyle(Lujo.marfil.opacity(0.88))
                .frame(maxWidth: ancho == nil ? .infinity : nil)
                .frame(width: ancho, height: Lujo.altoBoton)
                .padding(.horizontal, 22)
                .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous).fill(Lujo.marfil.opacity(0.025)))
                .cantoPulido(radio: Lujo.radioBoton)
                .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.45), trigger: toques)
    }
}

/// Terciario: solo texto pequeño con un icono fino. Rojizo apagado si borra.
struct BotonTerciarioLujo: View {
    let titulo: LocalizedStringKey
    var icono: IconoLujo? = nil
    var destructivo = false
    let accion: () -> Void
    @State private var toques = 0

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            HStack(spacing: 8) {
                if let icono {
                    IconoFino(icono: icono, color: destructivo ? Lujo.rojizo : Lujo.marfilSecundario, tamano: 15)
                }
                Text(titulo)
                    .font(.lujoEtiqueta(.caption, .regular))
                    .versalitas(1.4)
            }
            .foregroundStyle(destructivo ? Lujo.rojizo : Lujo.marfilSecundario)
            .frame(minHeight: Lujo.altoMinimo)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: toques)
    }
}

/// El botón redondo "+" de la barra, con el mismo metal del primario.
struct BotonMasLujo: View {
    let accion: () -> Void
    @State private var toques = 0

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            IconoFino(icono: .mas, color: Lujo.tinta, tamano: 20, trazo: 1.4)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo],
                                             startPoint: .top, endPoint: .bottom))
                        .shadow(color: Lujo.oroHondo.opacity(0.25), radius: 16, y: 8)
                }
                .overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .clear],
                                                              startPoint: .top, endPoint: .center), lineWidth: 0.75))
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: toques)
    }
}

// MARK: - Interruptor

/// Pista oscura con borde fino; un pulgar pequeño que se enciende en oro champán al activarse.
struct InterruptorLujo: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(Lujo.curva(0.45)) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 16) {
                configuration.label
                Spacer(minLength: 12)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.28))
                        .overlay(Capsule().strokeBorder(configuration.isOn ? Lujo.oro.opacity(0.55) : Lujo.marfil.opacity(0.16),
                                                        lineWidth: 0.75))
                    Circle()
                        .fill(configuration.isOn
                              ? AnyShapeStyle(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo],
                                                             startPoint: .top, endPoint: .bottom))
                              : AnyShapeStyle(Lujo.marfil.opacity(0.32)))
                        .frame(width: 18, height: 18)
                        .shadow(color: Lujo.oro.opacity(configuration.isOn ? 0.45 : 0), radius: 6)
                        .padding(4)
                }
                .frame(width: 46, height: 26)
            }
            .frame(minHeight: Lujo.altoMinimo)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: configuration.isOn)
        .accessibilityValue(configuration.isOn ? Text("Activado") : Text("Desactivado"))
    }
}

// MARK: - Campos

/// Un campo de texto que se ve editable: fondo muy sutil y una línea dorada fina al enfocarlo.
struct CampoTextoLujo: View {
    @Binding var texto: String
    let sugerencia: LocalizedStringKey
    var enfocado: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("", text: $texto, prompt: Text(sugerencia).foregroundStyle(Lujo.marfil.opacity(0.3)), axis: .vertical)
                .font(.zenoTitulo(.title3, .regular))
                .foregroundStyle(Lujo.marfil)
                .tint(Lujo.oro)                       // cursor dorado
                .lineLimit(1...3)
                .focused(enfocado)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            // La línea de abajo: casi invisible en reposo, oro fino al escribir.
            ZStack(alignment: .leading) {
                Rectangle().fill(Lujo.marfil.opacity(0.10))
                Rectangle()
                    .fill(LinearGradient(colors: [Lujo.oro, Lujo.oro.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
                    .scaleEffect(x: enfocado.wrappedValue ? 1 : 0.0001, anchor: .leading)
            }
            .frame(height: 0.75)
            .animation(Lujo.curva(), value: enfocado.wrappedValue)
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Lujo.marfil.opacity(0.035)))
        .contentShape(Rectangle())
        .onTapGesture { enfocado.wrappedValue = true }
    }
}

/// Un valor que se toca para cambiarlo: icono fino + valor. Abre un selector propio.
struct CampoDeValor<Valor: View>: View {
    let icono: IconoLujo
    var activo = false
    let accion: () -> Void
    @ViewBuilder var valor: Valor
    @State private var toques = 0

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            HStack(spacing: 10) {
                IconoFino(icono: icono, color: activo ? Lujo.oro : Lujo.marfilSecundario, tamano: 17)
                valor
                    .font(.zenoTexto(.callout))
                    .foregroundStyle(Lujo.marfil)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: Lujo.altoBoton)
            .background(RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous).fill(Lujo.marfil.opacity(0.035)))
            .cantoPulido(radio: Lujo.radioChip, oro: activo)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.selection, trigger: toques)
    }
}

// MARK: - Etiqueta de sección

struct EtiquetaLujo: View {
    let texto: LocalizedStringKey
    init(_ texto: LocalizedStringKey) { self.texto = texto }

    var body: some View {
        Text(texto)
            .font(.lujoEtiqueta(.caption2, .medium))
            .versalitas(2.0)
            .foregroundStyle(Lujo.marfilSecundario)
    }
}

// MARK: - Hoja que sube desde abajo (dentro del universo, no una hoja de sistema)

/// Presenta hojas encima de todo (también encima de la barra). Sin velo oscuro: la nebulosa sigue a la vista.
@Observable
final class Hojas {
    static let compartidas = Hojas()

    struct Hoja: Identifiable {
        let id = UUID()
        let contenido: AnyView
    }

    var pila: [Hoja] = []

    func mostrar<C: View>(@ViewBuilder _ contenido: () -> C) {
        withAnimation(Lujo.curva(0.6)) { pila.append(Hoja(contenido: AnyView(contenido()))) }
    }

    func cerrar() {
        guard !pila.isEmpty else { return }
        withAnimation(Lujo.curva(0.5)) { _ = pila.removeLast() }
    }
}

/// Va en la raíz del universo. Cada hoja sube desde abajo; tocar fuera o deslizarla hacia abajo la cierra.
struct CapaDeHojas: View {
    @State private var arrastre: CGFloat = 0
    private var hojas: Hojas { .compartidas }

    var body: some View {
        ZStack(alignment: .bottom) {
            if !hojas.pila.isEmpty {
                // Recoge el toque de fuera, sin oscurecer el cielo.
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { hojas.cerrar() }
                    .transition(.opacity)
            }
            ForEach(hojas.pila) { hoja in
                let esLaUltima = hoja.id == hojas.pila.last?.id
                VStack(spacing: 0) {
                    Capsule().fill(Lujo.marfil.opacity(0.22)).frame(width: 36, height: 4).padding(.top, 10)
                    hoja.contenido
                        .padding(.horizontal, Lujo.margen)
                        .padding(.top, 18)
                        .padding(.bottom, 34)
                }
                .frame(maxWidth: .infinity)
                .background(alignment: .top) {
                    // Cristal oscuro casi opaco: se lee lo de la hoja, no lo de detrás.
                    UnevenRoundedRectangle(topLeadingRadius: Lujo.radioHoja, topTrailingRadius: Lujo.radioHoja,
                                           style: .continuous)
                        .fill(Color(red: 0.065, green: 0.07, blue: 0.12))
                        .padding(.bottom, -60)          // llega hasta el borde de abajo de la pantalla
                        .shadow(color: .black.opacity(0.45), radius: 40, y: -6)
                }
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: Lujo.radioHoja, topTrailingRadius: Lujo.radioHoja,
                                           style: .continuous)
                        .strokeBorder(LinearGradient(colors: [Lujo.marfil.opacity(0.2), .clear],
                                                     startPoint: .top, endPoint: .init(x: 0.5, y: 0.25)), lineWidth: 0.75)
                        .allowsHitTesting(false)
                }
                .offset(y: esLaUltima ? max(arrastre, 0) : 0)
                .scaleEffect(esLaUltima ? 1 : 0.96, anchor: .top)
                .opacity(esLaUltima ? 1 : 0.6)
                .gesture(DragGesture()
                    .onChanged { arrastre = $0.translation.height }
                    .onEnded { v in
                        if v.translation.height > 90 { hojas.cerrar() }
                        withAnimation(Lujo.curva(0.4)) { arrastre = 0 }
                    })
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard)
    }
}
