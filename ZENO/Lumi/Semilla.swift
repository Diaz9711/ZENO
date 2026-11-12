import Foundation

/// La huella digital de una persona: un número estable que sale de su nombre
/// y su fecha de nacimiento. La misma entrada produce siempre el mismo número,
/// hoy, mañana y en cualquier teléfono.
struct Semilla: Hashable {
    let valor: UInt64

    init(valor: UInt64) {
        self.valor = valor
    }

    init(nombre: String, anio: Int, mes: Int, dia: Int) {
        // "  María " y "maria" son la misma persona.
        let limpio = nombre
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                     locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        let texto = "\(limpio)|\(anio)-\(mes)-\(dia)"

        // FNV-1a de 64 bits: sencillo y estable (no usar hashValue, cambia en cada arranque).
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in texto.utf8 {
            h ^= UInt64(byte)
            h = h &* 0x0000_0100_0000_01b3
        }
        self.valor = h
    }
}

/// Generador de números repetible (SplitMix64). Con la misma semilla
/// entrega siempre la misma secuencia: de ahí salen colores, forma y ritmo.
struct GeneradorDeSemilla {
    private var estado: UInt64

    init(_ semilla: Semilla) {
        estado = semilla.valor
    }

    mutating func siguiente() -> UInt64 {
        estado = estado &+ 0x9e37_79b9_7f4a_7c15
        var z = estado
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    /// Número entre 0 y 1.
    mutating func unidad() -> Double {
        Double(siguiente() >> 11) / Double(1 << 53)
    }

    /// Número dentro de un rango.
    mutating func entre(_ a: Double, _ b: Double) -> Double {
        a + (b - a) * unidad()
    }

    mutating func entero(_ rango: ClosedRange<Int>) -> Int {
        rango.lowerBound + Int(siguiente() % UInt64(rango.count))
    }
}
