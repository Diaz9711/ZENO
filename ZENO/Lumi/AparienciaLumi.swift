import Foundation
import simd

/// Familia de color del cielo. El oficial de ZENO es el azulado (decisión de Diaz);
/// el vino se conserva solo para comparar en el laboratorio.
enum TonoDeCielo: String, CaseIterable, Identifiable {
    case vino, azulado
    var id: String { rawValue }
}

/// Todo lo que hace única a una estrella y a su nebulosa.
/// Se calcula una sola vez a partir de la semilla; la persona no elige nada.
struct AparienciaLumi: Equatable {
    // Estrella
    var colorNucleo: SIMD3<Float>   // centro cálido, casi blanco dorado
    var colorCorona: SIMD3<Float>   // el oro de ZENO
    var colorHalo: SIMD3<Float>     // el color propio de cada persona
    var lobulos: Int                // forma del halo
    var profundidadLobulo: Double
    var sentidoDeGiro: Double       // +1 o -1
    var periodoRespiracion: Double  // segundos por respiración

    // Animación propia de cada persona
    var olaDeRayos: Int             // 0 = los rayos laten juntos; 1–3 = una ola los recorre
    var inclinacionOrbita: Double   // qué tan de canto se ve la órbita de las motas
    var giroOrbita: Double          // hacia dónde está ladeada esa órbita
    var ritmoDeFlote: Double        // forma del vaivén al flotar

    // Nebulosa
    var colorFondo: SIMD3<Float>    // azul profundo. Nunca negro.
    var colorNube: SIMD3<Float>
    var colorBrasa: SIMD3<Float>    // ámbar
    var colorOro: SIMD3<Float>
    var desplazamiento: SIMD2<Float> // qué trozo del cielo le tocó

    init(semilla: Semilla, cielo: TonoDeCielo = .azulado) {
        var g = GeneradorDeSemilla(semilla)

        // — Estrella —
        colorNucleo = Self.hsb(g.entre(0.095, 0.118), g.entre(0.30, 0.42), 1.0)
        colorCorona = Self.hsb(g.entre(0.070, 0.100), g.entre(0.68, 0.82), 1.0)
        // El halo puede ser de cualquier tono, siempre suave.
        colorHalo = Self.hsb(g.unidad(), g.entre(0.42, 0.68), 1.0)
        lobulos = g.entero(3...7)
        profundidadLobulo = g.entre(0.09, 0.22)
        sentidoDeGiro = g.unidad() < 0.5 ? -1 : 1
        periodoRespiracion = g.entre(4.2, 6.4)

        // — Nebulosa — de índigo-violeta a vino.
        let azul = cielo == .azulado
        let u = g.unidad()
        // Vino: de violeta a vino. Azulado: de azul profundo a índigo.
        let tono = azul ? 0.585 + 0.085 * u : 0.72 + 0.21 * u
        colorFondo = Self.hsb(tono, g.entre(0.66, 0.80), g.entre(0.175, 0.215) * (azul ? 1.12 : 1))
        let vecino = tono + g.entre(-0.07, 0.07)
        colorNube = Self.hsb(vecino, g.entre(0.52, 0.70), g.entre(0.40, 0.50))
        // Lo que rodea a la estrella: ámbar sobre vino; azul cielo sobre azul
        // (el ámbar mezclado con azul se vuelve gris).
        let ub = g.unidad()
        let sb = g.entre(0.62, 0.78)
        colorBrasa = azul ? Self.hsb(0.585 + 0.075 * ub, sb * 0.62, 0.95)
                          : Self.hsb(0.015 + 0.07 * ub, sb, 0.92)
        colorOro = Self.hsb(g.entre(0.100, 0.130), g.entre(0.45, 0.60), 1.0)
        desplazamiento = SIMD2(Float(g.entre(0, 60)), Float(g.entre(0, 60)))

        // — Animación — (al final, para no alterar los colores ya calculados)
        olaDeRayos = g.entero(0...3)
        inclinacionOrbita = g.entre(0.36, 1.0)
        giroOrbita = g.entre(0, .pi)
        ritmoDeFlote = g.entre(0.55, 1.45)
    }

    /// Tono, saturación y brillo (0–1) a rojo, verde y azul.
    static func hsb(_ h: Double, _ s: Double, _ b: Double) -> SIMD3<Float> {
        let tono = (h - floor(h)) * 6
        let i = Int(tono)
        let f = tono - Double(i)
        let p = b * (1 - s)
        let q = b * (1 - s * f)
        let t = b * (1 - s * (1 - f))
        let rgb: (Double, Double, Double)
        switch i % 6 {
        case 0: rgb = (b, t, p)
        case 1: rgb = (q, b, p)
        case 2: rgb = (p, b, t)
        case 3: rgb = (p, q, b)
        case 4: rgb = (t, p, b)
        default: rgb = (b, p, q)
        }
        return SIMD3(Float(rgb.0), Float(rgb.1), Float(rgb.2))
    }
}

/// Qué tan cálido está el cielo según la hora (0 = noche violeta, 1 = mañana dorada).
enum Cielo {
    static func calidez(hora: Double) -> Double {
        // Máximo a media mañana, mínimo cerca de las 10 de la noche.
        0.5 + 0.5 * cos((hora - 10) / 24 * 2 * .pi)
    }

    static func horaActual(_ fecha: Date = .now, calendario: Calendar = .current) -> Double {
        let c = calendario.dateComponents([.hour, .minute], from: fecha)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
    }
}
