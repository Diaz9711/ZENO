import Foundation

/// Cuánta calidad extra dibujan el cielo y Lumi (Diaz, 15 nov 2026: "más wow, más real").
/// 0 = como siempre, idéntico. 1 = luz de Lumi sobre el gas, más profundidad, estrellas brillantes
/// con puntas y un corazón con más detalle. Mismos colores y misma semilla.
enum CalidadVisual {
    static let clave = "calidadVisual"
    /// Se lee una vez al abrir; el interruptor de prueba lo cambia en vivo.
    static var nivel: Double = UserDefaults.standard.double(forKey: clave)
}
