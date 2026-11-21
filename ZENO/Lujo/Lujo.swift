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
            // Sin sombra difuminada: con muchas tarjetas en pantalla se recalculaba en cada cuadro
            // al desplazar. El canto pulido ya las separa del cielo.
            CristalDeTarjeta(radio: radio)
        }
        .cantoPulido(radio: radio)
    }
}

/// El cristal de las tarjetas. Sobre el cielo azul, el de siempre; sobre el negro, un gris
/// tinta neutro (Fable: el azul marino parecía pegado del otro cielo).
private struct CristalDeTarjeta: View {
    let radio: CGFloat
    @AppStorage(TonoDeCielo.clave) private var tono = TonoDeCielo.azulado
    var body: some View {
        RoundedRectangle(cornerRadius: radio, style: .continuous)
            .fill(tono == .negro ? Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.62) : Lujo.cristal)
    }
}

/// Un separador casi invisible dentro de una tarjeta.
struct SeparadorLujo: View {
    var body: some View {
        Rectangle().fill(Lujo.marfil.opacity(0.07)).frame(height: 0.5)
    }
}

// MARK: - Iconos finos (una sola familia, trazo de 1,1 pt)

enum IconoLujo { case calendario, reloj, papelera, campana, cerrar, mas, atras, check, ojo, ojoCerrado, cara, llave, microfono }

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
            case .ojo, .ojoCerrado:
                camino.move(to: p(0.08, 0.5))
                camino.addQuadCurve(to: p(0.92, 0.5), control: p(0.5, 0.12))
                camino.addQuadCurve(to: p(0.08, 0.5), control: p(0.5, 0.88))
                camino.addEllipse(in: CGRect(x: 0.39 * s, y: 0.39 * s, width: 0.22 * s, height: 0.22 * s))
                if icono == .ojoCerrado { camino.move(to: p(0.16, 0.84)); camino.addLine(to: p(0.84, 0.16)) }
            case .cara:
                // Un marco de Face ID dibujado: cuatro esquinas, ojos y sonrisa.
                for (x, y, dx, dy) in [(0.12, 0.12, 1.0, 1.0), (0.88, 0.12, -1.0, 1.0), (0.12, 0.88, 1.0, -1.0), (0.88, 0.88, -1.0, -1.0)] {
                    camino.move(to: p(x, y + 0.2 * dy)); camino.addLine(to: p(x, y)); camino.addLine(to: p(x + 0.2 * dx, y))
                }
                camino.move(to: p(0.36, 0.38)); camino.addLine(to: p(0.36, 0.46))
                camino.move(to: p(0.64, 0.38)); camino.addLine(to: p(0.64, 0.46))
                camino.move(to: p(0.36, 0.64)); camino.addQuadCurve(to: p(0.64, 0.64), control: p(0.5, 0.74))
            case .microfono:
                camino.addRoundedRect(in: CGRect(x: 0.38 * s, y: 0.10 * s, width: 0.24 * s, height: 0.46 * s),
                                      cornerSize: CGSize(width: 0.12 * s, height: 0.12 * s))
                camino.move(to: p(0.24, 0.44))
                camino.addQuadCurve(to: p(0.76, 0.44), control: p(0.5, 0.86))
                camino.move(to: p(0.5, 0.66)); camino.addLine(to: p(0.5, 0.88))
                camino.move(to: p(0.38, 0.88)); camino.addLine(to: p(0.62, 0.88))
            case .llave:
                camino.addEllipse(in: CGRect(x: 0.12 * s, y: 0.32 * s, width: 0.36 * s, height: 0.36 * s))
                camino.move(to: p(0.48, 0.5)); camino.addLine(to: p(0.88, 0.5))
                camino.move(to: p(0.76, 0.5)); camino.addLine(to: p(0.76, 0.64))
                camino.move(to: p(0.86, 0.5)); camino.addLine(to: p(0.86, 0.6))
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

    init(_ titulo: LocalizedStringKey, ancho: CGFloat? = nil, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.ancho = ancho
        self.accion = accion
    }

    var body: some View {
        // Desde el 21 nov 2026 (Diaz): el estándar `ZenoPrimaryButton`, a 48 pt para convivir en filas.
        ZenoPrimaryButton(titulo, ancho: ancho, alto: Lujo.altoBoton, accion: accion)
    }
}

struct EtiquetaPrimaria: View {
    let titulo: LocalizedStringKey
    let ancho: CGFloat?
    @Environment(\.isEnabled) private var activo

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
        Text(titulo)
            .font(.lujoEtiqueta(.footnote, .semibold))
            .versalitas(1.8)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Lujo.tinta)
            .frame(maxWidth: ancho == nil ? .infinity : nil)
            .frame(width: ancho, height: Lujo.altoBoton)
            .padding(.horizontal, 14)
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Lujo.marfil.opacity(0.88))
                .frame(maxWidth: ancho == nil ? .infinity : nil)
                .frame(width: ancho, height: Lujo.altoBoton)
                .padding(.horizontal, 14)
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

    /// El movimiento de las hojas: un resorte sin rebote, como las hojas del propio iPhone.
    /// Sigue al dedo, se puede interrumpir a mitad y nunca hace un corte.
    static let subida = Animation.spring(response: 0.44, dampingFraction: 0.90)
    static let bajada = Animation.spring(response: 0.36, dampingFraction: 0.95)

    @MainActor func mostrar<C: View>(@ViewBuilder _ contenido: () -> C) {
        withAnimation(Self.subida) { pila.append(Hoja(contenido: AnyView(contenido()))) }
        Fluidez.marcar("hoja")
    }

    @MainActor func cerrar() {
        guard !pila.isEmpty else { return }
        withAnimation(Self.bajada) { _ = pila.removeLast() }
        Fluidez.marcar("cierra-hoja")
    }
}

/// Va en la raíz del universo. Cada hoja sube desde abajo; tocar fuera o deslizarla hacia abajo la cierra.
struct CapaDeHojas: View {
    @State private var arrastre: CGFloat = 0
    private var hojas: Hojas { .compartidas }

    /// Hacia abajo la hoja sigue al dedo; hacia arriba se resiste, como una goma.
    private var desplazamiento: CGFloat {
        arrastre >= 0 ? arrastre : -6 * log(1 + (-arrastre) / 22)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if !hojas.pila.isEmpty {
                // Recoge el toque de fuera. Un velo muy leve da profundidad (la hoja queda delante)
                // sin tapar el cielo; se aclara al arrastrar la hoja hacia abajo.
                Color.black.opacity(0.20 * (1 - min(max(arrastre, 0) / 300, 1)))
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
                        .shadow(color: .black.opacity(0.35), radius: 22, y: -4)
                }
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: Lujo.radioHoja, topTrailingRadius: Lujo.radioHoja,
                                           style: .continuous)
                        .strokeBorder(LinearGradient(colors: [Lujo.marfil.opacity(0.2), .clear],
                                                     startPoint: .top, endPoint: .init(x: 0.5, y: 0.25)), lineWidth: 0.75)
                        .allowsHitTesting(false)
                }
                .offset(y: esLaUltima ? desplazamiento : 0)
                .scaleEffect(esLaUltima ? 1 : 0.96, anchor: .top)
                .opacity(esLaUltima ? 1 : 0.6)
                .gesture(DragGesture(minimumDistance: 4)
                    .onChanged { arrastre = $0.translation.height }
                    .onEnded { v in
                        // Se cierra si se arrastró lo bastante o si el dedo la lanzó hacia abajo.
                        if v.translation.height > 110 || v.predictedEndTranslation.height > 260 {
                            hojas.cerrar()
                            // Sigue bajando desde donde la soltó el dedo; no vuelve a subir.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { arrastre = 0 }
                        } else {
                            withAnimation(Hojas.subida) { arrastre = 0 }
                        }
                    })
                // Solo movimiento (sin fundido): la hoja entra entera, como un objeto real.
                .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: hojas.pila.count) { viejo, nuevo in nuevo > viejo }
    }
}

// MARK: - Hoja grande casi transparente (capas)

/// La hoja donde vive el contenido: esquinas de 32, casi invisible, con un canto fino.
/// Deja ver la nebulosa a través y por los bordes; nunca la tiñe ni la oscurece (decisión de Diaz).
struct HojaDeFondo: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Lujo.radioHoja, style: .continuous)
            .fill(Lujo.marfil.opacity(0.018))
            .overlay {
                RoundedRectangle(cornerRadius: Lujo.radioHoja, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Lujo.marfil.opacity(0.16), Lujo.marfil.opacity(0.0)],
                                                 startPoint: .top, endPoint: .center), lineWidth: 0.75)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, -60)          // sigue bajo la barra hasta el borde de la pantalla
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// El micrófono de dictar: fino; encendido en oro mientras escucha.
struct IconoMicrofono: View {
    var activo = false
    var body: some View {
        IconoFino(icono: .microfono, color: activo ? Lujo.oro : Lujo.marfil.opacity(0.75), tamano: 19)
            .overlay(alignment: .topTrailing) {
                if activo { Circle().fill(Lujo.oro).frame(width: 5, height: 5).offset(x: 3, y: -2) }
            }
    }
}

// MARK: - El botón de Hoy (Empezar / Terminé)

/// El botón principal de la tarjeta Ahora. Diaz (16 nov 2026): "súper genérico… que no parezca hecho por IA,
/// calidad y premium". Dos diseños de verdad distintos (consejo de Fable) y el de siempre; se cambian en vivo en
/// Ajustes → Modo de prueba (`disenoBoton`). Solo en Hoy: el resto de la app no cambia.
enum DisenoDeBotonDeAhora: Int, CaseIterable {
    case siempre, metal, capsula, emblema, estandar
    static let clave = "disenoBoton"
    /// Diaz eligió el Emblema (16 nov 2026).
    static let elegido = DisenoDeBotonDeAhora.emblema
    var nombre: String {
        switch self {
        case .siempre: "0 · El de siempre"; case .metal: "A · Metal"; case .capsula: "B · Cápsula con flecha"; case .emblema: "E · Emblema"; case .estandar: "F · Estándar (ZenoPrimaryButton)"
        }
    }
}

struct BotonDeAhora: View {
    let enMarcha: Bool
    var minutos: Int? = nil
    let accion: () -> Void
    @AppStorage(DisenoDeBotonDeAhora.clave) private var diseno = DisenoDeBotonDeAhora.elegido.rawValue
    @State private var toques = 0
    /// Mientras la placa gira no se aceptan toques (un doble toque terminaría la tarea sin querer).
    @State private var ultimoToque = Date.distantPast

    var body: some View {
        switch DisenoDeBotonDeAhora(rawValue: diseno) ?? .elegido {
        case .emblema:
            Button {
                guard Date.now.timeIntervalSince(ultimoToque) > 0.9 else { return }
                ultimoToque = .now
                toques += 1
                accion()
            } label: { EmblemaAnimado(enMarcha: enMarcha) }
                .buttonStyle(EstiloHundido())
                .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: toques)
        case .siempre:
            BotonPrimarioLujo(enMarcha ? "Terminé" : "Empezar", accion: accion)
        case .estandar:
            // Para comparar con el Emblema (Diaz decide): el botón estándar de ZENO.
            ZenoPrimaryButton(enMarcha ? "Terminé" : "Empezar", icono: enMarcha ? .check : nil, alto: 54, accion: accion)
        case .metal:
            Button { toques += 1; accion() } label: { PlacaDeMetal(titulo: enMarcha ? "Terminé" : "Empezar") }
                .buttonStyle(EstiloHundido())
                .sensoryFeedback(.impact(weight: .medium, intensity: 0.55), trigger: toques)
        case .capsula:
            Button { toques += 1; accion() } label: { CapsulaConFlecha(titulo: enMarcha ? "Terminé" : "Empezar", enMarcha: enMarcha) }
                .buttonStyle(EstiloHundido())
                .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: toques)
        }
    }
}

/// Al presionar se hunde de verdad (baja y se aprieta), y vuelve con un resorte sin rebote.
private struct EstiloHundido: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            // Al presionar, la placa se inclina un poco hacia adentro, como una tecla física.
            .rotation3DEffect(.degrees(configuration.isPressed ? 7 : 0), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

/// A · Metal: una placa de oro cepillado con canto oscuro abajo (grosor), luz arriba y la palabra grabada
/// (en Fraunces, con un hilo de luz debajo de cada letra, como el bajorrelieve).
private struct PlacaDeMetal: View {
    let titulo: LocalizedStringKey
    @Environment(\.isEnabled) private var activo

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: 15, style: .continuous)
        ZStack {
            // El canto: la placa tiene grosor (una franja más oscura asoma abajo).
            forma.fill(Lujo.oroHondo.opacity(0.95)).offset(y: 2.5)
            forma.fill(LinearGradient(stops: [.init(color: Color(red: 0.96, green: 0.90, blue: 0.75), location: 0),
                                              .init(color: Lujo.oro, location: 0.45),
                                              .init(color: Color(red: 0.78, green: 0.65, blue: 0.40), location: 1)],
                                      startPoint: .top, endPoint: .bottom))
            // Cepillado fino, como metal satinado.
            Canvas { ctx, size in
                var y: CGFloat = 0.5
                var n = 0
                while y < size.height {
                    var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(l, with: .color(.white.opacity(n % 3 == 0 ? 0.07 : 0.03)), lineWidth: 0.5)
                    y += 1.3; n += 1
                }
            }
            .clipShape(forma)
            // Luz en el borde de arriba y sombra fina abajo (dentro de la placa).
            forma.strokeBorder(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0), Lujo.oroHondo.opacity(0.6)],
                                              startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
            // La palabra grabada: oscura, con un hilo de luz justo debajo.
            ZStack {
                Text(titulo).font(.zenoTitulo(.title3, .regular)).foregroundStyle(.white.opacity(0.45)).offset(y: 0.8)
                Text(titulo).font(.zenoTitulo(.title3, .regular)).foregroundStyle(Color(red: 0.20, green: 0.15, blue: 0.08))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Lujo.altoBoton)
        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
        .opacity(activo ? 1 : 0.45)
        .contentShape(forma)
    }
}

/// B · Cápsula con flecha (del video de referencia de Diaz): una cápsula de luz marfil→oro con la palabra
/// a la izquierda, en minúsculas, y un círculo oscuro con una flecha fina a la derecha. En marcha, la flecha es un check.
private struct CapsulaConFlecha: View {
    let titulo: LocalizedStringKey
    let enMarcha: Bool
    @Environment(\.isEnabled) private var activo

    var body: some View {
        HStack(spacing: 0) {
            Text(titulo)
                .font(.zenoTexto(.callout, .semibold))
                .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.06))
                .padding(.leading, 22)
            Spacer(minLength: 8)
            ZStack {
                Circle().fill(Color(red: 0.11, green: 0.10, blue: 0.13))
                Circle().strokeBorder(.white.opacity(0.10), lineWidth: 0.6)
                if enMarcha {
                    TrazoDeCheck()
                        .stroke(Lujo.oroLuz, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 14, height: 11)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    FlechaFina()
                        .stroke(Lujo.oroLuz, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                        .frame(width: 15, height: 12)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(width: Lujo.altoBoton - 10, height: Lujo.altoBoton - 10)
            .padding(.trailing, 5)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: enMarcha)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Lujo.altoBoton)
        .background {
            Capsule().fill(LinearGradient(colors: [Color(red: 0.97, green: 0.94, blue: 0.86), Lujo.oroLuz, Lujo.oro],
                                          startPoint: .leading, endPoint: .trailing))
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 0.8))
                .shadow(color: Lujo.oro.opacity(0.30), radius: 16, y: 6)
        }
        .opacity(activo ? 1 : 0.45)
        .contentShape(Capsule())
    }
}

/// E · Emblema (elegido por Diaz): el oro cepillado de siempre con una estrellita de cuatro puntas delante
/// de la palabra; con la tarea en marcha, la estrellita se vuelve el check (con un giro suave).
private struct PlacaEmblema: View {
    let titulo: LocalizedStringKey
    let enMarcha: Bool
    @Environment(\.isEnabled) private var activo

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
        HStack(spacing: 10) {
            ZStack {
                if enMarcha {
                    TrazoDeCheck()
                        .stroke(Lujo.tinta, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 13, height: 10)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                } else {
                    EstrellitaDeCuatro()
                        .fill(Lujo.tinta.opacity(0.85))
                        .frame(width: 13, height: 13)
                        .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                removal: .scale(scale: 0.4).combined(with: .opacity)))
                }
            }
            .frame(width: 16, height: 16)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: enMarcha)
            Text(titulo)
                .font(.lujoEtiqueta(.footnote, .semibold))
                .versalitas(1.8)
                .foregroundStyle(Lujo.tinta)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Lujo.altoBoton)
        .background {
            ZStack {
                forma.fill(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo], startPoint: .top, endPoint: .bottom))
                // El cepillado del oro de siempre.
                Canvas { ctx, size in
                    var y: CGFloat = 1
                    while y < size.height {
                        var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(l, with: .color(.white.opacity(y.truncatingRemainder(dividingBy: 3) < 1 ? 0.06 : 0.025)), lineWidth: 0.5)
                        y += 1.5
                    }
                }
                .clipShape(forma)
            }
            .shadow(color: Lujo.oroHondo.opacity(0.22), radius: 18, y: 10)
        }
        .overlay(alignment: .top) {
            forma.strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.0)], startPoint: .top, endPoint: .center), lineWidth: 0.75)
        }
        .opacity(activo ? 1 : 0.4)
        .contentShape(forma)
    }
}

/// La placa Emblema con su animación 3D (Diaz: "algo único, increíble"; plan de Fable):
/// - Al empezar, la placa da media vuelta sobre su eje y en el reverso aparecen el check y "Terminé";
///   al asentarse, una sola banda de luz cruza el metal.
/// - El brillo del metal se mueve cuando se inclina el iPhone, como el oro de verdad (nunca en bucle).
/// - Con Reducir Movimiento: sin giro, solo el cambio.
private struct EmblemaAnimado: View {
    let enMarcha: Bool
    @State private var giro: Double = 0
    @State private var destello = 0
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    var body: some View {
        let fijo = ProcessInfo.processInfo.arguments.contains("-giroEmblema")
            ? UserDefaults.standard.double(forKey: "giroEmblema") * 180 : nil
        PlacaGiratoria(giro: fijo ?? giro, destello: destello, quieto: reducirMovimiento)
            .onAppear { giro = enMarcha ? 180 : 0 }
            .onChange(of: enMarcha) { _, nuevo in
                if reducirMovimiento { giro = nuevo ? 180 : 0; return }
                if nuevo {
                    withAnimation(.spring(response: 0.78, dampingFraction: 0.74)) { giro = 180 }
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.42))
                        destello += 1
                    }
                } else {
                    // De vuelta (paso siguiente u "Ahora no"): un giro corto y callado.
                    withAnimation(.easeInOut(duration: 0.42)) { giro = 0 }
                }
            }
    }
}

private struct PlacaGiratoria: View, Animatable {
    var giro: Double
    let destello: Int
    let quieto: Bool
    var animatableData: Double { get { giro } set { giro = newValue } }

    var body: some View {
        let reverso = giro > 90
        let forma = RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
        ZStack {
            FondoDeOroCepillado(forma: forma)
            BrilloSegunInclinacion(forma: forma, apagado: quieto)
            BandaDeLuz(forma: forma, disparo: destello)
            CaraDeEmblema(reverso: reverso)
                // El reverso se da vuelta otra vez para que no se lea al revés.
                .rotation3DEffect(.degrees(reverso ? 180 : 0), axis: (x: 1, y: 0, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: Lujo.altoBoton)
        .overlay(alignment: .top) {
            forma.strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.0)], startPoint: .top, endPoint: .center), lineWidth: 0.75)
        }
        // La placa entera gira sobre su eje horizontal, con perspectiva.
        .rotation3DEffect(.degrees(giro), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
        .shadow(color: Lujo.oroHondo.opacity(0.22), radius: 18, y: 10)
        .contentShape(forma)
    }
}

private struct CaraDeEmblema: View {
    let reverso: Bool
    var body: some View {
        HStack(spacing: 10) {
            Group {
                if reverso {
                    TrazoDeCheck()
                        .stroke(Lujo.tinta, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 13, height: 10)
                } else {
                    EstrellitaDeCuatro().fill(Lujo.tinta.opacity(0.85)).frame(width: 13, height: 13)
                }
            }
            .frame(width: 16, height: 16)
            Text(reverso ? "Terminé" : "Empezar")
                .font(.lujoEtiqueta(.footnote, .semibold))
                .versalitas(1.8)
                .foregroundStyle(Lujo.tinta)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// El oro cepillado de siempre (el mismo del botón primario).
private struct FondoDeOroCepillado: View {
    let forma: RoundedRectangle
    var body: some View {
        ZStack {
            forma.fill(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo], startPoint: .top, endPoint: .bottom))
            Canvas { ctx, size in
                var y: CGFloat = 1
                while y < size.height {
                    var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(l, with: .color(.white.opacity(y.truncatingRemainder(dividingBy: 3) < 1 ? 0.06 : 0.025)), lineWidth: 0.5)
                    y += 1.5
                }
            }
            .clipShape(forma)
        }
    }
}

/// El brillo del metal sigue la inclinación del iPhone (lee el sensor del cielo, sin encenderlo).
/// Vista aparte: solo ella se redibuja (30 veces por segundo), no la pantalla de Hoy.
private struct BrilloSegunInclinacion: View {
    let forma: RoundedRectangle
    let apagado: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: apagado || ModoAhorro.compartido.activo)) { _ in
            let t = Inclinacion.compartida.ultima
            GeometryReader { geo in
                RadialGradient(colors: [.white.opacity(0.30), .white.opacity(0)],
                               center: UnitPoint(x: 0.5 + t.x * 0.45, y: 0.2 + t.y * 0.35),
                               startRadius: 0, endRadius: geo.size.width * 0.38)
                    .blendMode(.softLight)
            }
            .clipShape(forma)
        }
        .allowsHitTesting(false)
    }
}

/// Una sola banda de luz que cruza el metal cuando la placa se asienta.
private struct BandaDeLuz: View {
    let forma: RoundedRectangle
    let disparo: Int
    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.55), .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.28)
                .rotationEffect(.degrees(18))
                .keyframeAnimator(initialValue: -0.4, trigger: disparo) { vista, x in
                    vista.offset(x: geo.size.width * x)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(-0.4, duration: 0.01)
                        CubicKeyframe(1.3, duration: 0.85)
                    }
                }
                .frame(maxHeight: .infinity)
        }
        .clipShape(forma)
        .opacity(disparo == 0 ? 0 : 1)
        .allowsHitTesting(false)
    }
}

/// Una flecha fina hacia la derecha.
struct FlechaFina: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.move(to: CGPoint(x: r.maxX - r.height * 0.5, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.height * 0.5, y: r.maxY))
        return p
    }
}
