import SwiftUI

/// Los colores y letras de ZENO dentro de la extensión (no puede leer los de la app).
/// Mismos valores que `Lujo`: oro champán solo para controles y textos, nunca para Lumi.
enum Tinta {
    static let oro = Color(red: 0xD9 / 255, green: 0xC0 / 255, blue: 0x8A / 255)
    static let oroHondo = Color(red: 0xB8 / 255, green: 0x97 / 255, blue: 0x5A / 255)
    static let marfil = Color(red: 0xF2 / 255, green: 0xEC / 255, blue: 0xDD / 255)
    static let marfilSecundario = marfil.opacity(0.62)
    /// Azul profundo de la nebulosa. Nunca negro puro.
    static let cielo = Color(red: 0.035, green: 0.06, blue: 0.17)
    static let cieloClaro = Color(red: 0.10, green: 0.16, blue: 0.38)

    static func color(_ lista: [Double], _ fallback: Color = .white) -> Color {
        guard lista.count == 3 else { return fallback }
        return Color(red: lista[0], green: lista[1], blue: lista[2])
    }
}

extension Font {
    static func titulo(_ tamano: CGFloat, cursiva: Bool = false) -> Font {
        .custom(cursiva ? "Fraunces-Italic" : "Fraunces-Light", size: tamano)
    }
    static func texto(_ tamano: CGFloat, _ peso: String = "Regular") -> Font {
        .custom("Manrope-\(peso)", size: tamano)
    }
}

/// La luz de Lumi, simplificada (un widget no puede correr el shader): corazón nítido,
/// halo del color de cada persona y rayos finos. Con poca energía, más pequeña y tenue; igual de nítida.
struct LuzDeLumi: View {
    var foto: FotoDeZeno

    var body: some View {
        Canvas { ctx, size in
            let lado = min(size.width, size.height)
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let e = min(max(foto.energia, 0), 1)
            let escala = 0.88 + 0.12 * e
            let brillo = 0.85 + 0.15 * e
            let nucleo = Tinta.color(foto.nucleo)
            let corona = Tinta.color(foto.corona)
            let halo = Tinta.color(foto.halo)

            // Halo amplio del color propio.
            let rHalo = lado * 0.5 * escala
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - rHalo, y: c.y - rHalo, width: rHalo * 2, height: rHalo * 2)),
                     with: .radialGradient(Gradient(stops: [
                        .init(color: corona.opacity(0.75 * brillo), location: 0),
                        .init(color: corona.opacity(0.30 * brillo), location: 0.22),
                        .init(color: halo.opacity(0.30 * brillo), location: 0.45),
                        .init(color: halo.opacity(0), location: 1)]),
                        center: c, startRadius: 0, endRadius: rHalo))

            if !foto.esfera {
                // Rayos finos que se adelgazan hacia la punta.
                let n = max(4, min(8, foto.rayos))
                let largo = lado * 0.46 * escala
                for i in 0..<n {
                    let a = Double(i) / Double(n) * 2 * .pi - .pi / 2
                    let punta = CGPoint(x: c.x + cos(a) * largo, y: c.y + sin(a) * largo)
                    let ancho = lado * 0.016
                    let lado1 = CGPoint(x: c.x + cos(a + .pi / 2) * ancho, y: c.y + sin(a + .pi / 2) * ancho)
                    let lado2 = CGPoint(x: c.x + cos(a - .pi / 2) * ancho, y: c.y + sin(a - .pi / 2) * ancho)
                    var p = Path()
                    p.move(to: lado1); p.addLine(to: punta); p.addLine(to: lado2); p.closeSubpath()
                    ctx.fill(p, with: .linearGradient(Gradient(colors: [nucleo.opacity(0.95 * brillo), corona.opacity(0)]),
                                                      startPoint: c, endPoint: punta))
                }
            }

            // Corazón: en la estrella, sin borde; en la esfera, bola de luz con contorno nítido.
            let rNucleo = lado * (foto.esfera ? 0.22 : 0.15) * escala
            let rect = CGRect(x: c.x - rNucleo, y: c.y - rNucleo, width: rNucleo * 2, height: rNucleo * 2)
            ctx.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(stops: [
                .init(color: .white.opacity(brillo), location: 0),
                .init(color: nucleo.opacity(brillo), location: 0.35),
                .init(color: corona.opacity(foto.esfera ? brillo : 0.6 * brillo), location: foto.esfera ? 0.92 : 0.75),
                .init(color: corona.opacity(foto.esfera ? 0.9 * brillo : 0), location: 1)]),
                center: c, startRadius: 0, endRadius: rNucleo))
        }
        .accessibilityLabel(Text("Lumi, tu estrella"))
    }
}

/// El fondo de nebulosa, simplificado: azul profundo que se aclara hacia Lumi. Nunca negro.
struct CieloDelWidget: View {
    var foto: FotoDeZeno
    var centro: UnitPoint = .center

    var body: some View {
        let fondo = Tinta.color(foto.fondo, Tinta.cielo)
        ZStack {
            fondo
            RadialGradient(colors: [Tinta.cieloClaro.opacity(0.9), fondo.opacity(0)],
                           center: centro, startRadius: 0, endRadius: 170)
        }
    }
}
