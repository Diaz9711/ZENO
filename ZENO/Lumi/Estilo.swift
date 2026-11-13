import SwiftUI

// MARK: - Colores de ZENO

extension Color {
    /// El oro de Lumi: acentos, bordes encendidos.
    static let oroZeno = Color(red: 1.0, green: 0.80, blue: 0.48)
    /// Texto principal: blanco cálido, nunca blanco puro de sistema.
    static let marfil = Color(red: 1.0, green: 0.975, blue: 0.94)
}

// MARK: - Tipografía

extension Font {
    /// Títulos y frases: serifa fina (New York), con voz propia y calma de libro.
    static func zenoTitulo(_ estilo: Font.TextStyle, _ peso: Font.Weight = .light) -> Font {
        .system(estilo, design: .serif, weight: peso)
    }

    /// Botones y textos pequeños: redondeada, clara y amable.
    static func zenoTexto(_ estilo: Font.TextStyle, _ peso: Font.Weight = .regular) -> Font {
        .system(estilo, design: .rounded, weight: peso)
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
                .font(.system(size: tamano, weight: .ultraLight, design: .serif))
                .tracking(tamano * 0.42)
                .padding(.leading, tamano * 0.42)      // compensa el espacio tras la última letra
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
