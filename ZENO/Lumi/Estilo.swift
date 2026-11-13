import SwiftUI

// MARK: - Colores de ZENO

extension Color {
    /// El oro de Lumi: acentos, bordes encendidos.
    static let oroZeno = Color(red: 1.0, green: 0.80, blue: 0.48)
    /// Texto principal: blanco cálido, nunca blanco puro de sistema.
    static let marfil = Color(red: 1.0, green: 0.975, blue: 0.94)
}

// MARK: - Tipografía

/// Letras propias de ZENO (incluidas en la app; licencia OFL en /Licencias):
/// Fraunces para títulos y frases, Manrope para el texto pequeño y Bebas Neue para el logotipo.
extension Font {
    /// Tamaños base de cada estilo; con `relativeTo:` siguen creciendo con Dynamic Type.
    private static func tamano(_ estilo: Font.TextStyle) -> CGFloat {
        switch estilo {
        case .largeTitle: 36
        case .title: 29
        case .title2: 23
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    private static func manrope(_ peso: Font.Weight) -> String {
        switch peso {
        case .ultraLight, .thin: "Manrope-ExtraLight"
        case .light: "Manrope-Light"
        case .medium: "Manrope-Medium"
        case .semibold: "Manrope-SemiBold"
        case .bold, .heavy, .black: "Manrope-Bold"
        default: "Manrope-Regular"
        }
    }

    /// Títulos y frases: Fraunces, la voz de ZENO (elegida por Diaz).
    static func zenoTitulo(_ estilo: Font.TextStyle, _ peso: Font.Weight = .light, cursiva: Bool = false) -> Font {
        let fuerte = [.medium, .semibold, .bold, .heavy, .black].contains(peso)
        let nombre = cursiva
            ? (fuerte ? "Fraunces-SemiBoldItalic" : (peso == .regular ? "Fraunces-Italic" : "Fraunces-LightItalic"))
            : (fuerte ? "Fraunces-SemiBold" : (peso == .regular ? "Fraunces-Regular" : "Fraunces-Light"))
        return .custom(nombre, size: tamano(estilo), relativeTo: estilo)
    }

    /// Botones y textos pequeños: Manrope, clara y moderna.
    static func zenoTexto(_ estilo: Font.TextStyle, _ peso: Font.Weight = .regular) -> Font {
        .custom(manrope(peso), size: tamano(estilo), relativeTo: estilo)
    }

    /// El logotipo: Bebas Neue, como pide la especificación.
    static func zenoMarca(_ tamano: CGFloat) -> Font {
        .custom("BebasNeue-Regular", fixedSize: tamano)
    }
}

// MARK: - Cristal: el material de los botones y campos

extension View {
    /// Vidrio oscuro con borde de luz dorada, en vez de un gris plano de sistema.
    /// `fuerte` para la acción principal; `activo` para lo elegido.
    func cristal(radio: CGFloat = 999, fuerte: Bool = false, activo: Bool = false) -> some View {
        background {
            let forma = RoundedRectangle(cornerRadius: radio, style: .continuous)
            ZStack {
                forma.fill(.ultraThinMaterial).opacity(0.6)
                forma.fill(LinearGradient(
                    colors: [Color.marfil.opacity(fuerte || activo ? 0.17 : 0.08),
                             Color.marfil.opacity(fuerte || activo ? 0.05 : 0.015)],
                    startPoint: .top, endPoint: .bottom))
                forma.strokeBorder(LinearGradient(
                    colors: [Color.oroZeno.opacity(activo ? 0.95 : (fuerte ? 0.6 : 0.32)),
                             Color.marfil.opacity(0.06),
                             Color.oroZeno.opacity(activo ? 0.45 : 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: activo ? 1.3 : 1)
            }
            .shadow(color: Color.oroZeno.opacity(activo ? 0.30 : (fuerte ? 0.16 : 0)), radius: 16)
        }
    }
}

/// Al tocar: se hunde un poco y vuelve con un pequeño rebote. Respuesta inmediata.
struct EstiloPresion: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Logotipo

/// La marca ZENO: un pequeño sol dorado sobre letras finas y espaciadas.
struct MarcaZeno: View {
    var tamano: CGFloat = 54

    var body: some View {
        VStack(spacing: tamano * 0.28) {
            SolZeno()
                .frame(width: tamano * 0.62, height: tamano * 0.62)
            Text(verbatim: "ZENO")
                .font(.zenoMarca(tamano * 1.15))
                .tracking(tamano * 0.38)
                .padding(.leading, tamano * 0.38)      // compensa el espacio tras la última letra
                .foregroundStyle(LinearGradient(colors: [.marfil, Color.oroZeno.opacity(0.85)],
                                                startPoint: .top, endPoint: .bottom))
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "ZENO"))
    }
}

/// El sol de la marca, dibujado: núcleo dorado y un anillo fino de luz.
struct SolZeno: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2
            let disco = Path(ellipseIn: CGRect(x: c.x - r * 0.42, y: c.y - r * 0.42, width: r * 0.84, height: r * 0.84))
            ctx.addFilter(.shadow(color: Color.oroZeno.opacity(0.9), radius: r * 0.45))
            ctx.fill(disco, with: .radialGradient(Gradient(colors: [.marfil, .oroZeno, Color(red: 0.98, green: 0.6, blue: 0.3)]),
                                                  center: CGPoint(x: c.x - r * 0.12, y: c.y - r * 0.14),
                                                  startRadius: 0, endRadius: r * 0.5))
            let anillo = Path(ellipseIn: CGRect(x: c.x - r * 0.86, y: c.y - r * 0.86, width: r * 1.72, height: r * 1.72))
            ctx.stroke(anillo, with: .color(Color.oroZeno.opacity(0.55)), lineWidth: max(1, r * 0.05))
        }
    }
}

// MARK: - Íconos propios

/// Ícono de ajustes de ZENO: una pequeña órbita con su estrella, en vez de un engranaje genérico.
struct IconoOrbita: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2
            var orbita = Path(ellipseIn: CGRect(x: c.x - r * 0.92, y: c.y - r * 0.42, width: r * 1.84, height: r * 0.84))
            orbita = orbita.applying(CGAffineTransform(translationX: -c.x, y: -c.y)
                .concatenating(CGAffineTransform(rotationAngle: -.pi / 7))
                .concatenating(CGAffineTransform(translationX: c.x, y: c.y)))
            ctx.stroke(orbita, with: .color(Color.marfil.opacity(0.75)), lineWidth: 1.3)
            let nucleo = Path(ellipseIn: CGRect(x: c.x - r * 0.26, y: c.y - r * 0.26, width: r * 0.52, height: r * 0.52))
            ctx.fill(nucleo, with: .color(.oroZeno))
            let luna = Path(ellipseIn: CGRect(x: c.x + r * 0.62, y: c.y - r * 0.62, width: r * 0.26, height: r * 0.26))
            ctx.fill(luna, with: .color(Color.marfil.opacity(0.9)))
        }
        .frame(width: 26, height: 26)
    }
}

// MARK: - Texto con luz

extension View {
    /// Títulos que brillan sobre el cielo: marfil que se calienta hacia abajo,
    /// una sombra que los separa del gas y un halo dorado muy leve.
    func luminoso() -> some View {
        self
            .foregroundStyle(LinearGradient(colors: [.marfil, Color(red: 1.0, green: 0.88, blue: 0.70)],
                                            startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.5), radius: 10, y: 2)
            .shadow(color: Color.oroZeno.opacity(0.22), radius: 20)
    }
}

/// Etiqueta pequeña en mayúsculas espaciadas y dorada: ordena la pantalla como una revista.
struct Etiqueta: View {
    let texto: LocalizedStringKey
    init(_ texto: LocalizedStringKey) { self.texto = texto }

    var body: some View {
        HStack(spacing: 8) {
            Capsule().fill(Color.oroZeno.opacity(0.6)).frame(width: 14, height: 1)
            Text(texto)
                .textCase(.uppercase)
                .font(.zenoTexto(.caption2, .semibold))
                .tracking(2.6)
                .foregroundStyle(Color.oroZeno)
            Capsule().fill(Color.oroZeno.opacity(0.6)).frame(width: 14, height: 1)
        }
        .shadow(color: .black.opacity(0.5), radius: 6)
    }
}

// MARK: - Botón secundario con ícono dibujado

enum IconoZeno { case mas, lista }

/// Una acción secundaria: píldora de cristal con su ícono propio.
struct BotonSecundario: View {
    let titulo: LocalizedStringKey
    let icono: IconoZeno
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 9) {
                Canvas { ctx, size in
                    let w = size.width, h = size.height
                    var p = Path()
                    switch icono {
                    case .mas:
                        p.move(to: CGPoint(x: w / 2, y: h * 0.18)); p.addLine(to: CGPoint(x: w / 2, y: h * 0.82))
                        p.move(to: CGPoint(x: w * 0.18, y: h / 2)); p.addLine(to: CGPoint(x: w * 0.82, y: h / 2))
                    case .lista:
                        for (i, y) in [0.25, 0.5, 0.75].enumerated() {
                            p.move(to: CGPoint(x: w * (i == 1 ? 0.3 : 0.12), y: h * y))
                            p.addLine(to: CGPoint(x: w * 0.88, y: h * y))
                        }
                    }
                    ctx.stroke(p, with: .color(.oroZeno), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }
                .frame(width: 13, height: 13)
                Text(titulo)
                    .font(.zenoTexto(.subheadline, .medium))
                    .tracking(0.3)
            }
            .foregroundStyle(Color.marfil)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .cristal()
        }
        .buttonStyle(EstiloPresion())
    }
}

// MARK: - Interruptor propio

struct InterruptorZeno: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { configuration.isOn.toggle() }
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: 14)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn
                              ? AnyShapeStyle(LinearGradient(colors: [.oroZeno, Color(red: 0.98, green: 0.62, blue: 0.32)],
                                                             startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Color.marfil.opacity(0.10)))
                        .overlay(Capsule().strokeBorder(Color.oroZeno.opacity(configuration.isOn ? 0 : 0.35), lineWidth: 1))
                        .shadow(color: Color.oroZeno.opacity(configuration.isOn ? 0.45 : 0), radius: 10)
                    Circle()
                        .fill(Color.marfil)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                        .padding(3)
                }
                .frame(width: 54, height: 31)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: configuration.isOn)
        .accessibilityValue(configuration.isOn ? Text("Activado") : Text("Desactivado"))
    }
}
