import Foundation
import simd

/// Familia de color del cielo. El oficial de ZENO es el azulado (decisión de Diaz);
/// el vino se conserva solo para comparar en el laboratorio.
/// `negro` (Diaz, 15 nov 2026): opción en Ajustes. Cielo casi negro con la misma nube de la persona
/// y una estrella hermana (parecida, no igual). El azulado no cambia en nada.
enum TonoDeCielo: String, CaseIterable, Identifiable {
    case vino, azulado, negro
    var id: String { rawValue }

    static let clave = "tonoDeCielo"
    /// El que eligió la persona (por defecto, el azul de siempre).
    static var elegido: TonoDeCielo {
        UserDefaults.standard.string(forKey: clave).flatMap(TonoDeCielo.init(rawValue:)) ?? .azulado
    }
}

/// Lo que identifica al cielo que se ve, para fundir uno con otro al cambiarlo.
struct CieloElegido: Hashable {
    let semilla: Semilla
    let tono: TonoDeCielo
}

/// Todo lo que hace única a una estrella y a su nebulosa.
/// Se calcula una sola vez a partir de la semilla; la persona no elige nada.
struct AparienciaLumi: Equatable {
    // Estrella
    var colorNucleo: SIMD3<Float>   // centro cálido, casi blanco dorado
    var colorCorona: SIMD3<Float>   // el oro de ZENO
    var colorHalo: SIMD3<Float>     // el color propio de cada persona
    /// La luz de cada estrella vive entre dos tonos vecinos y va y viene entre ellos, muy despacio.
    var colorCoronaVecino: SIMD3<Float>
    var colorNucleoVecino: SIMD3<Float>
    var periodoDeLuz: Double        // segundos que tarda en ir y volver
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
    var colorFondo: SIMD3<Float>    // azul profundo (o tinta casi negra en `.negro`). Nunca 0.
    var colorNube: SIMD3<Float>
    var colorBrasa: SIMD3<Float>    // ámbar
    var colorOro: SIMD3<Float>
    var desplazamiento: SIMD2<Float> // qué trozo del cielo le tocó

    init(semilla: Semilla, cielo: TonoDeCielo = .azulado) {
        var g = GeneradorDeSemilla(semilla)

        // — Estrella —
        // (Los sorteos van en variables, en el mismo orden de siempre: el azulado sale idéntico.)
        let hN = g.entre(0.115, 0.135), sN = g.entre(0.26, 0.36)
        colorNucleo = Self.hsb(hN, sN, 1.0)
        // Oro de estrella: amarillo pálido, nunca naranja (mismo criterio que `Color.oroZeno`).
        let hC = g.entre(0.112, 0.132), sC = g.entre(0.50, 0.62)
        colorCorona = Self.hsb(hC, sC, 1.0)
        // El halo puede ser de cualquier tono, siempre suave.
        // El halo puede ser de cualquier tono menos amarillo-verde, verde o turquesa: sobre el azul
        // del cielo esos se ven sucios.
        // Los tonos de la franja verde se corren a su borde más cercano; los demás no cambian.
        var tonoHalo = g.unidad()
        if tonoHalo > 0.10 && tonoHalo < 0.64 { tonoHalo = tonoHalo < 0.30 ? 0.10 : 0.64 }
        let sH = g.entre(0.42, 0.68)
        colorHalo = Self.hsb(tonoHalo, sH, 1.0)
        lobulos = g.entero(3...7)
        profundidadLobulo = g.entre(0.09, 0.22)
        sentidoDeGiro = g.unidad() < 0.5 ? -1 : 1
        periodoRespiracion = g.entre(4.2, 6.4)

        // — Nebulosa — de índigo-violeta a vino.
        // El negro parte del azulado (mismos sorteos) y se transforma al final.
        let azul = cielo != .vino
        let u = g.unidad()
        // Vino: de violeta a vino. Azulado: de azul profundo a índigo.
        let tono = azul ? 0.585 + 0.085 * u : 0.72 + 0.21 * u
        let sF = g.entre(0.66, 0.80), bF = g.entre(0.175, 0.215)
        colorFondo = Self.hsb(tono, sF, bF * (azul ? 1.12 : 1))
        let vecino = tono + g.entre(-0.07, 0.07)
        let sNu = g.entre(0.52, 0.70), bNu = g.entre(0.40, 0.50)
        colorNube = Self.hsb(vecino, sNu, bNu)
        // Lo que rodea a la estrella: ámbar sobre vino; azul cielo sobre azul
        // (el ámbar mezclado con azul se vuelve gris).
        let ub = g.unidad()
        let sb = g.entre(0.62, 0.78)
        colorBrasa = azul ? Self.hsb(0.585 + 0.075 * ub, sb * 0.62, 0.95)
                          : Self.hsb(0.015 + 0.07 * ub, sb, 0.92)
        let hO = g.entre(0.100, 0.130), sO = g.entre(0.45, 0.60)
        colorOro = Self.hsb(hO, sO, 1.0)
        desplazamiento = SIMD2(Float(g.entre(0, 60)), Float(g.entre(0, 60)))

        // — Animación — (al final, para no alterar los colores ya calculados)
        olaDeRayos = g.entero(0...3)
        inclinacionOrbita = g.entre(0.36, 1.0)
        giroOrbita = g.entre(0, .pi)
        ritmoDeFlote = g.entre(0.55, 1.45)

        // — Luz viva — sin sorteos nuevos: el oro aprobado respira hacia un oro un poco más cálido.
        colorCoronaVecino = Self.hsb(0.108, 0.62, 1.0)
        colorNucleoVecino = Self.hsb(0.112, 0.34, 1.0)
        periodoDeLuz = 70 + 40 * Double(desplazamiento.x) / 60

        // — Cielo negro (Diaz, 15 nov 2026; colores aconsejados por Fable) —
        // Con los mismos sorteos: tinta casi negra con un susurro del tono de la persona (nunca 0,
        // para que el grano no se corte), humo azul-violeta y luz de luna alrededor de la estrella
        // (el ámbar o el oro oscurecido se vuelven marrón sobre negro).
        // La estrella es su hermana: blanco dorado, platino en el centro, halo menos saturado.
        if cielo == .negro {
            let tonoN = 0.585 + 0.16 * u
            // Prueba de comparación (se quita al elegir): 1 = más hondo.
            let hondo = UserDefaults.standard.integer(forKey: "negroHondo") == 1
            colorFondo = Self.hsb(tonoN, sF * (hondo ? 0.60 : 0.85), bF * (hondo ? 0.13 : 0.26))
            colorNube = Self.hsb(tonoN + (vecino - tono), sNu * (hondo ? 0.38 : 0.62), bNu * (hondo ? 0.52 : 0.74))
            colorBrasa = Self.hsb(0.60 + 0.06 * ub, sb * (hondo ? 0.30 : 0.50), hondo ? 0.40 : 0.50)
            colorOro = Self.hsb(0.112 + (hO - 0.10) * 0.6, sO * 0.80, 1.0)
            colorNucleo = Self.hsb(hN, sN * 0.55, 1.0)
            colorCorona = Self.hsb(hC + 0.006, sC * 0.72, 1.0)
            colorHalo = Self.hsb(tonoHalo, sH * 0.70, 1.0)
            colorCoronaVecino = Self.hsb(0.116, 0.46, 1.0)
            colorNucleoVecino = Self.hsb(0.118, 0.20, 1.0)
        }
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
